---
layout: post
title: Version Control Without Git - Store our project files in the Hub
date: 2025-09-09 05:00:00 +0300
tags: administration
image: /assets/2025-09-09/title.png
image_header: /assets/2025-09-09/title_landscape.png
bg_alternative: true
read_more_links:
  - name: Organisation & Administration
    url: /category/administration
---
Every Peakboard application and flow is a development artifact that deserves proper handling. In a professional context, this means that these artifacts should be managed in a way aligned with common industry standards of security and documentation.
When it comes to documentation, a Peakboard project (whether a regular design project or Flow) includes built-in documentation such as description texts and comments that we can bind to controls and other parts of the project.
Besides documentation, versioning is a huge topic and a crucial requirement in industrial software development. The most common way to do this is [Git](https://git-scm.com/), a free and open source tool to track all changes of development artifacts from the beginning of the project to the latest version. In this article, we discuss a lightweight alternative to Git. The Peakboard Hub, available both online and on-prem, offers a built-in document management system to store and version PBMX files (design projects) and PFX files (Flow projects) in a similar way to Git.

## File Management in Peakboard Hub

We can access Peakboard Hub's file management through the regular Hub portal. In this article, we will use Hub Online, but it works the same way in the on-prem version.
A common way to organize is to create a directory structure to store PBMX/PFX files along with other artifacts. The screenshot shows a dedicated directory for all PBMX files.

![image](/assets/2025-09-09/010.png)

## Handling the files in Peakboard Designer

In Peakboard Designer, we can choose to store a project file on the local file system — which is what we would do when using versioning with Git — or in the Hub. In the subsequent dialog we select the appropriate directory.

![image](/assets/2025-09-09/020.png)

To load a project we can also choose between the file system and Hub storage.

## Versioning

All documents stored in the Hub are automatically versioned. To access a version other than the current file, we can right-click on a file and then choose `Manage Versions`. Any stored version from the past can be restored.

![image](/assets/2025-09-09/030.png)

![image](/assets/2025-09-09/040.png)

## Permissions

It's a common practice to restrict access, especially write access, to as few users as possible. Assigning rights to certain groups of users works the same as anywhere else in the Hub. We assign the activity to specific user groups. The screenshot shows how to configure the directory for the project files. Everyone can read or download the files, but only the users who are part of the Developer group can write into the directory and change files.

![image](/assets/2025-09-09/050.png)

## Deployment

Of course, we can use the traditional way of deploying projects from the Designer to the box or BYOD instance. However, if we decide to store and version the projects in the Hub, we can deploy them directly from the file management by right-clicking the PBMX file.

![image](/assets/2025-09-09/060.png)

## Conclusion

Today we explored the basic ideas behind using Peakboard Hub's file management to store, organize, and version Peakboard project files. When we compare this method with the traditional use of Git, we can see that it is a very good trade-off for teams that do not have a Git architecture in place yet. However, Git also offers features that cannot be replaced by the Hub, such as "Pull Requests" or other development workflows that go beyond just storing and versioning. This makes it more suitable for small teams with limited need for sophisticated Git features.



