---
title: "Site Architecture Overview"
description: "Overview of the tools and technologies I have used and plan to use, with a little explanation of why I'm reinventing some wheels."
date: "2023-01-10"
draft: false
---

Getting started is the hard part for me. Write what you know, I suppose. One thing I know is how this site is set up. I'll summarize the architecture in this post and get into more detail in subsequent posts.

The source code for the site is all hosted on [github](https://github.com/gsarjeant/gregsarjeant.net) (there's also a handy link at the top-right of the site). The GCP infrastructure is managed with terraform. The site itself is a [Next.js](https://nextjs.org) application deployed to [Google Cloud Run](https://cloud.google.com/run).

I've spent the last few years working in [Google Cloud](https://cloud.google.com) (GCP), so I thought it would be fun to take what I've learned and set up a website there. I'm also interested to see how cost-effective I can make this. Public cloud platforms can get very expensive, but they don't have to be. For most needs (networking, service hosting, data storage, etc.), there are options that are billed based on usage. The per-unit costs for these are usually pretty low. That means that this will be comparatively inexpensive, since I expect it to be a low-traffic site.

I'd also like the site to be lightweight and fast. Most of this is going to be static content (text, images, etc.), so I should be able to pregenrate most of the content. I shouldn't nee do to server-side processing to handle most requests (at least for now). This will also help with the usage-based billing.

Finally, I don't want to manually configure the cloud infrastructure. I've used infrastructure-as-code technologies for 10 years or so, and I strongly prefer managing infrastructure with something like [terraform](https://www.terraform.io) to managing it manually.

Given all that, the overarching principles behind the site architecture are:

1. Manage all cloud infrastructure as code.
1. Use Google Cloud technologies that are billed based on usage, rather than uptime or CPU class or anything like that.
1. Use open-source technologies and frameworks.
1. Statically generate as much content as possible.

## Infrastructure as Code
I used [terraform](https://www.terraform.io) to define most of the site infrastructure in code. The two exceptions to this are:

* The domain itself, which I registered manually through Google Domains
* The GCP project, which I created manually

Neither of these is currently supported by terraform (GCP project creation is supported if you have an Organization, but I don't and creating one for this purpose is overkill). That's okay, though. This is a reasonable amount of manual bootstrapping. The terraform code is [here](https://github.com/gsarjeant/gregsarjeant.net/tree/main/terraform/).


## GCP Infrastructure
The site runs on [Cloud Run](https://cloud.google.com/run). I knew I wanted to use one of the GCP [serverless offerings](https://cloud.google.com/serverless). I initially considered [App Engine](https://cloud.google.com/appengine/) because I am most familiar with it. I also thought it might be fun to build the site entirely in Cloud Functions. In the end I decided to go with [Cloud Run](https://cloud.google.com/run/docs/quickstarts) for a few reasons:

* Much of the reason for doing this is to learn some new things, and I've been using App Engine for 4 years or so.
* Google appears to be much more committed to Cloud Run than to App Engine.
* I wanted to work directly with the docker containers. I could also do this with App Engine Flexible, but at that point why not just use Cloud Run? I'm also not a fan of app startup on App Engine Flexible.
* Though the site's not terribly complicated, there's enough going on that it makes sense to run services in containers. I think it would have been a stretch to try to pull this all off in Cloud Functions.
* Cloud Run lets me deny access to the internal google URLs for the services, which Cloud Functions currently doesn't. I want to ensure that all traffic to the site is coming through the Load Balancer.

Cloud Run sits in a comfortable place for me - it has many of the stengths of App Engine and Cloud Functions but avoids their biggest weaknesses. So far, I'm happy with it. I'm maintaining control over the elements of the site that are important to me (container runtime, languages and frameworks, load balancer configs, etc.) and relinquishing control over things I'm less concerned about for this project (container scheduler configuration, artifact repository configuration, etc.).

## Technologies and Frameworks

The site is a [Next.js](https://github.com/vercel/next.js/) application. The application code is [here](https://github.com/gsarjeant/gregsarjeant.net/tree/main/web).  Next.js is a [React](https://reactjs.org) framework that provides some nice capabilities like static site generation and client-side routing. I'm using [MaterialUI](https://github.com/mui/material-ui) components for the majority of the UI elements.

I originally used [Hugo](https://gohugo.io) and implemented the site as a purely static site served from a Cloud Storage bucket. This was very quick to get up and running and easy to maintain, but I moved to Next.js because:

* My interaction with the Hugo site was essentially reduced to writing Markdown to create content. I've done plenty of that, so I wasn't really learning much new after the initial configuration and theme selection.
* I've been wanting to improve my understanding of JavaScript for years. The last time I did anything with JavaScript was something like 2001 or 2002. It's changed considerably since then. That hasn't mattered too much to me, because in that time I've shifted my focus to systems and infrastructure. But over the last couple years it's started to bother me that modern JavaScript has started to look like magic. Next.js required me to write JavaScript, which I wanted. It also let me work with React and learn a bit about how UI elements are managed nowadays.
* I would like to have some dynamic content that is backed by APIs (mine and third parties'). It wasn't clear how to do that with Hugo, but it looked like whatever I did was going to be a hack that Hugo wasn't really happy about. Next.js supports a few different ways to do this.

## Static content

The Next.js [Getting Started guide](https://nextjs.org/docs) is great, and basically walks you through building a static site generator. The content is written in [Markdown](https://www.markdownguide.org), and some commonly used npm libraries convert the Markdown to HTML. I used the walkthrough to get a sense for how Next.js works and then extended the resulting site to add some more features (draft posts, MUI components, etc.)

Because the site is static, I can cache it, reducing round-trips to the server and increasing performance. This also allows routing to happen at the client, further reducing those round trips. The result is a lightweight, snappy site (though of course it's also tiny right now).

## Conclusion and next steps

For the first iteration of this site I've used Next.js to build ... a static site generator that is driven off of Markdown. So I spent a couple weeks building something that took about an hour of setup with hugo. But I'm not doing this for speed. I now have a deeper understanding of how the site works, more control over how it behaves, and a lot more room for it to grow. It's been a fun project and I'm looking forward to adding content and functionality over time.

I'll follow this post up with some deeper descriptions of the various elements for anyone interested in a bit more detail about how the site is configured. The next things I'll be working on for the site are:

1. Automatic deployments to Cloud Run using github actions or similar
1. Unit and integration tests
1. Automatic testing prior to deployment
1. API-driven content