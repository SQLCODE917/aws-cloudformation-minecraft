# AWS CloudFormation Template for Minecraft Bedrock Server

This template provides an easy way of hosting a private Minecraft Bedrock (Pocket Edition) server in AWS. You will just need to create a new CloudFormation stack using the `minecraft-server.yml` template, and adjusting the parameters where needed. The stack will take care of provisioning the required resources.

The aim is to have all the configurations related to both the application server itself, and the related infrastructural resources, in one single place.

## Prerequisites

Before creating the stack, you should create, or have an ***EC2 key pair*** ready in region where you're planning to host the server.

## Resources

The server itself will be a regular EC2 instance of a chosen capacity, based on an Ubuntu server image.

That server will be placed in its own separate VPC, in its own subnet located in the chosen availability zone. Connectivity to the internet is provided by a dedicated internet gateway using the necessary route tables and resource attachments.

By default the security group of the server only allows UDP traffic to the ports that were allocated for the Bedrock server application. Everything else is blocked. If you need to connect to the server via SSH, you should manually open the port 22 in that security group.

A static ***Elastic IP*** is provisioned and attached to the server by the stack when configured to do so.

A private S3 bucket is created for hosting Minecraft world backups.

When the server is configured to shut down automatically following a given schedule, this stack will create two ***lambda functions***, one of which will have the capability to stop the EC2 instance, and the other to start it. Stopping will be conducted periodically following the schedule and using EventBridge Rules. Starting will be conducted manually by knocking the HTTP API created as part of this stack.

Bedrock server properties from the stack configuration are stored in Parameter Store in AWS Systems Manager. They are compiled to a format that is compatible with the server.properties file. Bedrock server source URL is also stored in the Parameter Store.

More sensitive parameters, i.e. permissions, whitelist and custom script URL are stored in AWS SecretsManager.

## Server and Software

The server uses a special shell script to configure and potentially update the Bedrock server on every boot. Any changes made to the server settings outside of the CloudFormation Stack configuration will be lost on the next start up.

If you need to run special commands as part of the server boot process, you can use the stack parameter `CustomStartupScriptURL` to define a URL to a script that should be executed just prior to launching the Bedrock server. Notice that this custom script will be executed as `root`, so make sure you vet the sources carefully.

The Bedrock server software is located in `/usr/games/minecraft` and the binary is being executed within a [screen](https://linux.die.net/man/1/screen) session as the user `games`.

Worlds are being automatically backed up to the dedicated S3 bucket whenever the server is being shut down, either due to an action initiated within the virtual machine, or from the outside gracefully stopping the entire instance.

## Todos and Ideas

- IPv6 support
- Decouple the User Script from the template
- Automatic clean up of old Bedrock distributable versions
- Tools to easily restore Worlds from a backup file
- Stream logs from the server to CloudWatch