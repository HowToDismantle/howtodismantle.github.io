---
layout: post
title: Plug-in, Baby - The Ultimate Guide to Building Your Own Peakboard Extensions - The Basics
date: 2025-11-03 02:00:00 +0000
tags: dev
image: /assets/2025-11-03/title.png
image_header: /assets/2025-11-03/title.png
bg_alternative: true
read_more_links:
  - name: Other developer articles
    url: /category/dev
  - name: Peakboard Extension Kit
    url: https://www.nuget.org/packages/Peakboard.ExtensionKit/
  - name: Extension template for Visual Studio
    url: https://marketplace.visualstudio.com/items?itemName=Peakboard.PBEKTEMP
downloads:
  - name: Source code for this article
    url: https://github.com/HowToDismantle/howtodismantle.github.io/tree/main/assets/2025-12-05/MeowExtension
---
Peakboard Designer provides built-in data sources for almost any modern hardware and software that you'd find in an office, warehouse, or factory. And even when you do have an unsupported device or program, you can usually use a generic data source to connect to it---like ODBC for databases or JSON for REST services. We've discussed this method multiple times on our blog, so feel free to browse [the archives](/archive/) to learn more.

But what if you have an unsupported device or program, but you can't (or don't want to) use a generic data source? In that case, you can create your own **custom extension**, with Peakboard's easy-to-use plug-in system. Here's how it works:
1. You build a DLL for your extension by writing some .NET code.
1. You install your extension in Peakboard Designer.
1. You use the custom data source you built.

Peakboard extensions open the door to custom-made integrations. And in this four-part series on our blog, we'll explain how to build these extensions, from a basic example all the way to a sophisticated example with complex parameters and event-triggered sources:

* [Part I - The Basics](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-The-Basics.html)
* [Part II - Parameters and User Input](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Parameters-and-User-Input.html)
* [Part III - Custom-made Functions](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Fun-with-Functions.html)
* [Part IV - Event-Triggered Data Sources](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Event-triggered-data-sources.html)


In this article, we're going to build a very basic Peakboard extension called **Meow Extension**, which returns a static list of cats (which we will hard-code into the extension). You can download the [source code for Meow Extension](https://github.com/HowToDismantle/howtodismantle.github.io/tree/main/assets/2025-12-05/MeowExtension), if you want to follow along.


## Set up the project

In order to develop a Peakboard extension, we first need to install a NuGet package called [`Peakboard.ExtensionKit`](https://www.nuget.org/packages/Peakboard.ExtensionKit/).

Then, we create a new .NET project with the `Library` output format and the `.NET 8` target framework.

We create a new file called `extension.xml` and add some metadata about our extension. This file gets copied to the output folder, and Peakboard Designer uses the file to get basic information about our extension.

Here's our `extension.xml` file:
{% highlight xml %}
<?xml version="1.0" encoding="utf-8" ?>
<ExtensionCatalog xmlns="http://schemas.peakboard.com/pbmx/2020/extensions">
  <Extensions>
    <Extension ID="MeowExtension"
               Path="Meow.dll"
               Version="1.2"
               Class="MeowExtension.MeowExtension" />
  </Extensions>
</ExtensionCatalog>
{% endhighlight %}

We also create an icon (ideally a PNG) for our extension. We add the icon to our project as an embedded resource.

Now, we create our .NET project file:
{% highlight xml %}
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>Library</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <GenerateAssemblyInfo>false</GenerateAssemblyInfo>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Peakboard.ExtensionKit" Version="4.0.1" />
  </ItemGroup>

  <ItemGroup>
    <None Include="extension.xml">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
    <EmbeddedResource Include="MeowExtension.png" />
  </ItemGroup>

</Project>
{% endhighlight %}


## Create the classes

Next, we create the two classes that define our extension's functionality:
1. The `MeowExtension` class, which represents our extension.
1. The `CatCustomList` class, which represents the data source that our extension provides.

### Create the extension class

First, we create the class that represents our extension. To do this, we define a new class called `MeowExtension`, which extends `ExtensionHost` (the base class for all extensions).

Next, we override the `GetDefinitionOverride()` method. This method provides metadata about our extension to the *extension runtime*. Note: this is different from the `extension.xml` file, which provides metadata to *Peakboard Designer*. However, the metadata in this method must match the metadata in `extension.xml`, to ensure consistency.

Next, we override the `GetCustomListsOverride()` method. This method defines all the **list data sources** that our extension provides. For example, if you are building an extension for an ERP system, then your extension could provide a *customers* list-data-source and an *orders* list-data-source. Then, in Peakboard Designer, you can choose which data source you want to add. Both data sources are provided by the same extension.

For Meow Extension, we provide a single data source: a static list of cats. So, our `GetCustomListsOverride()` method simply returns a new `CatCustomList` object. (We define the `CatCustomList` class in the next section.)

Here's what our final `MeowExtension` class looks like:
{% highlight csharp %}
public class MeowExtension : ExtensionBase
{
    public MeowExtension(IExtensionHost host) : base(host) { }
    
    protected override ExtensionDefinition GetDefinitionOverride()
    {
        return new ExtensionDefinition
        {
            ID = "MeowExtension",
            Name = "Meow Extension",
            Description = "A Peakboard extension for cats",
            Version = "1.2",
            Author = "Meow Development Team",
            Company = "Meow Inc.",
            Copyright = "Copyright © Meow Inc.",
        };
    }

    protected override CustomListCollection GetCustomListsOverride()
    {
        return new CustomListCollection
        {
            new CatCustomList(),
        };
    }
}
{% endhighlight %}

### Create the list class

Now, we create the class for `CatCustomList`. This class represents the cats list data source that our extension provides. `CatCustomList` extends `CustomListBase` (the base class for all custom list data sources).

First, we override the `GetDefinitionOverride` method. This method provides metadata about the data source. The host system uses this method to handle the extension properly, and Peakboard Designer uses the method to provide information about the extension.

Here's what our `CatCustomList` class looks like, with the `GetDefinitionOverride()` method:
{% highlight csharp %}
[CustomListIcon("Meow.MeowExtension.png")]
public class CatCustomList : CustomListBase
{
    protected override CustomListDefinition GetDefinitionOverride()
    {
        return new CustomListDefinition
        {
            ID = "CatCustomList",
            Name = "Cat List",
            Description = "A custom list for cats with breed and age information",
        };
    }

    // [......]

}
{% endhighlight %}

Next, we override the `GetColumnsOverride` method. This method defines the columns of our data source. Each column has a name and data type (`Number`, `String`, or `Boolean`).

The columns in our cats list never change, so we return a simple collection of columns, for things like the name, age, and breed of cat. But you can also [make the columns dynamic](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Parameters-and-User-Input.html) and change them based on the parameters that the user sets.

{% highlight csharp %}
protected override CustomListColumnCollection GetColumnsOverride(CustomListData data)
{
    var columns = new CustomListColumnCollection();
    columns.Add(new CustomListColumn("ID", CustomListColumnTypes.Number));
    columns.Add(new CustomListColumn("Name", CustomListColumnTypes.String));
    columns.Add(new CustomListColumn("Breed", CustomListColumnTypes.String));
    columns.Add(new CustomListColumn("Age", CustomListColumnTypes.Number));
    columns.Add(new CustomListColumn("ImageUrl", CustomListColumnTypes.String));
    return columns;
}
{% endhighlight %}

The final method we override is `GetItemsOverride()`. This method provides the actual list data for our data source.

The method returns a `CustomListObjectElementCollection` object, which represents the list data. A `CustomListObjectElementCollection` object contains one `CustomListObjectElement` object for each row of data.

A `CustomListObjectElement` object represents a single row in the list. A `CustomListObjectElement` object contains a collection of key-value pairs---one for each column in the row. Each key-value pair represents a column within the row.

So altogether, it looks like this:
```
CustomListObjectElementCollection (the list):
    - CustomListObjectElement (a row in the list):
        - Key-value (a column in the row)
        - Key-value (a column in the row)
        ...
    - CustomListObjectElement (a row in the list):
        - Key-value (a column in the row)
        - Key-value (a column in the row)
        ...
    - CustomListObjectElement (a row in the list):
        - Key-value (a column in the row)
        - Key-value (a column in the row)
        ...
    ...
```

Here's what our `GetItemsOverride()` method looks like:

{% highlight csharp %}
protected override CustomListObjectElementCollection GetItemsOverride(CustomListData data)
{
    var items = new CustomListObjectElementCollection();
    
    // Add cat data directly to items
    var item1 = new CustomListObjectElement();  // A row.
    item1.Add("ID", 1);                         // A key-value pair.
    item1.Add("Name", "Fluffy1");               // Another key-value pair.
    item1.Add("Breed", "Persian");
    item1.Add("Age", 3);
    item1.Add("ImageUrl", "https://example.com/cat1.jpg");
    items.Add(item1);
    
    var item2 = new CustomListObjectElement();
    item2.Add("ID", 2);
    item2.Add("Name", "Whiskers");
    item2.Add("Breed", "Maine Coon");
    item2.Add("Age", 5);
    item2.Add("ImageUrl", "https://example.com/cat2.jpg");
    items.Add(item2);
    
    return items;
}
{% endhighlight %}


## Assemble the extension

Now, we compile our code. Once that's done, we put all the binaries into a single ZIP file. For our example, we only have the DLL binary file. But depending on the extension you're building, you may have other artifacts, such as debug symbols or other referenced assemblies that your extension depends on---all of these need to go inside the ZIP file.

We also put our `extension.xml` file into the ZIP file. That way, Peakboard Designer can read the metadata.

When we install our extension, everything from the ZIP file gets loaded into Peakboard Designer. And when the Peakboard app is deployed to a Peakboard Box or BYOD instance, everything inside the ZIP file is also deployed to the device running the app.

![image](/assets/2025-11-03/peakboard-extension-zip-contents.png)

## Install the extension in Peakboard Designer

In order to use our extension in Peakboard Designer, we first need to install it:
1. Add a new data source.
1. Select *Extensions*.
1. Click *Add custom extension*.
1. Select the ZIP file for your extension.
1. Close and restart Peakboard Designer.

![image](/assets/2025-11-03/peakboard-designer-install-extension-dialog.png)

Now, we can add our Cat List data source:
1. Add a new data source.
1. Select *Extensions*.
1. In *Meow Extension*, click *Add*.
1. Select *Cat List*.

![image](/assets/2025-11-03/peakboard-designer-custom-list-selection.png)

Now, the dialog for our data source pops up. We click the preview refresh button, and our static list of cats appears:

![image](/assets/2025-11-03/peakboard-designer-data-preview.png)

Right now, our extension doesn't have any parameters that the user can set. But don't worry---we'll cover that in the [next article in our series](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Parameters-and-User-Input.html)!