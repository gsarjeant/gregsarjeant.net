---
title: "Site Architecture Overview"
description: "Overview of the tools and technologies I have used and plan to use, with a little explanation of why I'm reinventing some wheels."
date: "2023-01-09"
draft: false
---

Getting started is the hard part for me. Write what you know, I suppose. One thing I know is how this site is set up. I'll briefly summarize the architecture in this post and get into more detail in subsequent posts.

I've spent the last few years working in Google Cloud (GCP), so I thought it would be fun to take what I've learned and set up a website there. I'm also interested to see how cost-effective I can make this. There are plenty of services that will host a personal site for a small monthly fee. My hope is that by using GCP technologies that are billed based upon usage, I can build something that's not too much more expensive, but over which I have more control. It's also a fun excuse to experiment.

My first goal was to define the entire site in code. The two exceptions to this are:

* The domain itself, which I registered manually through Google Domains
* The GCP project, which I created manually

Neither of these is currently supported by terraform (project creation is if you have an Organization, but I don't and creating one for this purpose is overkill). That's okay, though. This is also a reasonable amount of manual bootstrapping.

The source code for the site is all hosted on [github](https://github.com/gsarjeant/gregsarjeant.net) (there's also a handy link at the top-right of the site). The GCP infrastructure is managed with terraform. The site itself is a [Next.js](https://nextjs.org) application deployed to Google Cloud Run.

## Infrastructure

The GCP infrastructure includes all of the entities and services that are required to host the site and to manage its configuration with terraform.

__[Base Infrastructure](https://github.com/gsarjeant/gregsarjeant.net/tree/main/terraform/configurations/base):__ This infrastructure is used to bootstrap terraform. I use similar core infrastructure for a number of projects, so I've moved this configuration into its own [module](https://github.com/gsarjeant/gcp-bootstrap). The module does the following:
* Enable required GCP APIs
* Create a service account for terraform operations.
* Grant admin accounts token creator permissions for the terraform account to allow admins to perform terraform operations via impersonation
* Create a versioned cloud storage bucket to store the terraform state
* Create a dedicated KMS keyring and key to encrypt the terraform state

__[Site Infrastructure](https://github.com/gsarjeant/gregsarjeant.net/tree/main/terraform/configurations/site):__ This is the infrastructure that backs the site. It defines the following entities:
* SSL Certificate for the domain 
* A load balancer that routes incoming traffic to the appropriate backend.
    * Traffic to gregsarjeant.net is directed to Cloud Run.
        * http:// is redirected to https://
    * All other traffic (direct requests to the public IP, spoofed domains, etc.) is directed to a black hole cloud storage bucket that serves a 404 page. There's no legitmate reason for any of this traffic, so I'd rather just route it away from Cloud Run entirely.
* Backends and Network Endpoint Groups that provide the load balancer targets.
* The Cloud Storage bucket that stores the 404 page for the blackhole.
* A service account to be used by Cloud Run. This account has no permissions to anything in Google Cloud.
* An artifact repository for deployed docker images.
* A Cloud Armor security policy that denies any inbound traffic that doesn't match the domain (gregsarjeant.net)
    * This has no effect in practice because of the blackhole redirect, but I wanted to get a Cloud Armor policy in place that I could modify later.

If you look through the code, you'll see one or two entities that I didn't mention above - e.g. App Engine and Firebase. These are vestigial bits of infrastructure from my initial configuration, which I did on App Engine. I changed my mind and decided to use Cloud Run, but once Firebase and App Engine are created in a project, they can't be destroyed, so I left those in the terraform configuration to reflect the state of the project.


