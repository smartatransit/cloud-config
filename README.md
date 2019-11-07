# cloud-config
This repository (and its integration with the free Terraform Cloud service) allows `smartatransit` team members to deploy Docker resources to our cloud host. In the future it could be used to deploy other cloud infrastructure outside of the host at well.

To deploy a service, clone the repository (or pull the `master` branch if it's already cloned) and create a new branch for your work. Create a new file like `my_service_name.tf`, where you'll place your Terraform configuration. Below is a sample of what that might look like.

When you're done, push your branch and open a pull request against the `master` branch. This should automatically start a `terraform plan` job in Terraform Cloud, which you should be able to view if you're a member of the `smartatransit` organization. Just click the link in the newly created status check on your pull request. When the plan job finishes, it'll show you a summary of the changes that your pull request will make.

If drift or manual intervention has changed the state from what `master` said it should be, this may include more changes than you intended, as Terraform attempts to bring things back into line. One common example you may see is that a Docker service in production is marked with an image tag like `smartatransit/scrapedumper:398urf9uei`, and terraform wants to change it back to something like `smartatransit/scrapedumper:production`, using the human-readable name it sees in the TF configuration. These sorts of changes are generally harmless. If you see something in the Terraform plan that you don't understand, it's suggested that you reach out to a team member familiar with the affected area before proceeding.

When you're confident that the Terraform plan describes what you want it to, you're ready to merge your pull request to master. Merging will trigger another build in the Terraform Cloud workspace, this time running the `terraform apply` command rather than `terraform plan`. If all goes well, the result will be your service deployed successfully to the host.

## Example

```hcl
variable "myservice_postgres_password" {
  type = "string"
}

resource "docker_secret" "myservice_postgres_password" {
  name = "myservice_postgres_password"
  data = base64encode(var.myservice_postgres_password)
}

resource "docker_network" "myservice" {
  name   = "myservice"
  driver = "overlay"
}

resource "docker_volume" "postgres_data" {
  name = "myservice"
}

resource "postgresql_role" "myservice" {
  name     = "myservice"
  login    = true
  password = var.myservice_postgres_password
}

resource "postgresql_database" "myservice" {
  name  = "myservice"
  owner = postgresql_role.smartadata.name
}

resource "docker_service" "myservice" {
  name = "myservice"

  task_spec {
    container_spec {
      image = "smartatransit/myservice:production"

      env = {
        DEBUG         = "true"
        POSTGRES_HOST = var.postgres_host
      }

      mounts {
        target = "/myservice-data-dir"
        source = docker_volume.myservice.name
        type   = "volume"
      }

      secrets {
        secret_id   = docker_secret.myservice_postgres_password.id
        secret_name = docker_secret.myservice_postgres_password.name
        file_name   = "/run/secrets/myservice_postgres_password"
      }
    }

    networks = [docker_network.myservice.id]
  }
}
```

The `variable` blocks are used to declare names for values that are going to be passed in from outside the configuration. This is useful for sensitive values like passwords which we don't want checked into this repository. You can then add the value directly in the Terraform Cloud web UI by selecting the "Variables" tab. If your variable is a sensitive value like a password, make sure to check the "Sensitive" box so Terraform knows to censor this value in the log output.

The `resource` blocks each create and manage a resource either from the Docker provider or the Postgresql provider. Documentation for those can be found [here](https://www.terraform.io/docs/providers/docker/) and [here](https://www.terraform.io/docs/providers/postgresql/).

Notice that this example references the variable `var.postgres_host`, which is not defined here. You can reference variables in other files to create links among the service. Terraform will build a graph to determine the correct order in which to create or update resources, but it will break if there are circular references.

For more information on Terraform and HCL (the configuration language it relies on) see [the documentation](https://www.terraform.io/intro/index.html) or reach out to your fellow team members for help!
