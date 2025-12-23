---
layout: post
title: Plug-in, Baby - The Ultimate Guide to Building Your Own Peakboard Extensions - Parameters and User Input
date: 2025-12-05 00:00:00 +0000
tags: dev
image: /assets/2025-12-05/title.png
image_header: /assets/2025-12-05/title.png
bg_alternative: true
read_more_links:
  - name: Other developer articles
    url: /category/dev
  - name: Extension template for Visual Studio
    url: https://marketplace.visualstudio.com/items?itemName=Peakboard.PBEKTEMP
downloads:
  - name: Source code for this article
    url: https://github.com/HowToDismantle/howtodismantle.github.io/tree/main/assets/2025-12-05/MeowExtension
---
This article is part two of our custom Peakboard extensions series:

* [Part I - The Basics](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-The-Basics.html)
* [Part II - Parameters and User Input](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Parameters-and-User-Input.html)
* [Part III - Custom-made Functions](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Fun-with-Functions.html)
* [Part IV - Event-triggered data sources](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Event-triggered-data-sources.html)

In the [first part of this series](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-The-Basics.html), we explained how to build a simple Peakboard extension called `MeowExtension`. We created two classes in .NET:
* One for specifying the extension metadata.
* One for defining the *Cat List* data source.

In today's article, we're going to take things one step further: We'll add some configuration options to our Cat List data source. These are the options that the user sees when they add a new Cat List data source. (Just like how the JSON data source has configuration options for the source URL, authentication type, path, etc.)

Make sure that you have read the [first part of this series](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-The-Basics.html). This article won't make sense otherwise. You can also take a look at the [final code for this article](https://github.com/HowToDismantle/howtodismantle.github.io/tree/main/assets/2025-12-05/MeowExtension).

## Add a text parameter

Now, let's add a simple text parameter for the cat's name, to our Cat List data source. To do this, we need to modify our `CustomCatList` class:
1. Set `PropertyInputPossible` to `true`, to indicate that our data source has parameters that the user can set.
1. Create a new `CustomListPropertyDefinition` to define our text parameter.
1. Add the `CustomListPropertyDefinition` object to the `PropertyInputDefaults` collection. This registers the property with the data source.

Note: In our last article, we used a standalone `CustomCatList` class definition. But here, we're just going to use an object initializer inside the `GetDefinitionOverride` function.

{% highlight csharp %}
protected override CustomListDefinition GetDefinitionOverride()
{
    return new CustomListDefinition
    {
        ID = "CatCustomList",
        Name = "Cat List",
        Description = "A custom list for cats with breed and age information",
        PropertyInputPossible = true,
        PropertyInputDefaults =
        {
            new CustomListPropertyDefinition { Name = "CatsName", Value = ""}
        }
    };
}
{% endhighlight %}

Here's what our parameter looks like in Peakboard Designer:

![Peakboard custom list text parameter input](/assets/2025-12-05/peakboard-text-parameter-configuration.png)

## Get the parameter value

Of course, adding a parameter on its own isn't very useful. We also want to use the value of the parameter (either the value that the user entered, or the default).

To get the value of a parameter, we override the `GetItemsOverride` function. This function provides a `data` object that contains a `Properties` collection. This collection contains all the parameter values. So, to get the value for our `CatsName` parameter, we do this:

{% highlight csharp %}
protected override CustomListObjectElementCollection GetItemsOverride(CustomListData data)
{
    this.Log.Info("Generating cat list items for " + data.Properties["CatsName"]);

    // ....
}
{% endhighlight %}

We print the value of the `CatsName` parameter, by using the `Log` object. `Log` works as you would expect, and it supports all the standard logging levels, like `Info`, `Verbose`, `Error`, `Critical`, etc.

## Validate the parameter value

The extension kit provides a standardized way to validate parameter values. That way, if the user enters an invalid value, Peakboard Designer will let them know and prevent them from saving the data source---until they fix the parameter value.

To validate a parameter value, we override the `CheckDataOverride` function. We process the parameter's value, and if there's a problem, we throw an exception. The exception message is shown to the user, to let them know what's wrong with the value they entered.

For our `CatsName` parameter, let's make sure that the parameter value is not empty:
{% highlight csharp %}
protected override void CheckDataOverride(CustomListData data)
{
    if (string.IsNullOrWhiteSpace(data.Properties["CatsName"]))
    {
        throw new InvalidDataException("Please provide a good name");
    }
    base.CheckDataOverride(data);
}
{% endhighlight %}

## Add non-text parameters

Now, what if we want to add a non-text parameter? For example, a boolean or a numeric parameter? In that case, the process is mostly the same---but we need to set the `TypeDefinition` field of our `CustomListPropertyDefinition` object.

Let's create two new parameters:
* `IsItARealCat`, a boolean.
* `Age`, a number.

{% highlight csharp %}
new CustomListPropertyDefinition { Name = "IsItARealCat", Value = "True", TypeDefinition = TypeDefinition.Boolean },
new CustomListPropertyDefinition { Name = "Age", Value = "4", TypeDefinition = TypeDefinition.Number },
{% endhighlight %}

Like before, we also need to add the new parameters to our `PropertyInputDefaults` collection. Here's what our new parameters look like. You can see that Peakboard Designer handles their data types correctly.

![Peakboard boolean and number parameter settings](/assets/2025-12-05/peakboard-boolean-number-parameter-settings.png)

## Add a selectable-values parameter

Now, let's say that we have a parameter where we don't want the user to enter arbitrary values. Instead, we want them to choose from a predetermined selection of values. To do this, we set the `selectableValues` attribute of our `TypeDefinition`. We set `selectableValues` to the values we want the user to choose from.

In this example, we define a numeric parameter, and we give it a few possible values:
{% highlight csharp %}
new CustomListPropertyDefinition { Name = "MaximumOfSomething", Value = "5", 
      TypeDefinition = TypeDefinition.Number.With(selectableValues: [ 2, 3, 5, 10, 20, 50, 100]) },
{% endhighlight %}

And here's what it looks like in Peakboard Designer. You can see that the user gets a drop-down list, in order to choose the value that they want:
![Peakboard parameter selectable values dropdown](/assets/2025-12-05/peakboard-selectable-values-dropdown.png)

## Add a masked parameter

For passwords, connection strings, and any other potentially sensitive data, we want to mask the text that the user types in. To do this, we set the `TypeDefinition` attribute `masked` to `true`:

{% highlight csharp %}
new CustomListPropertyDefinition { Name = "MySecretCode", Value = "18899", TypeDefinition = TypeDefinition.String.With(masked: true) },
{% endhighlight %}

Here's what the masked parameter looks like:

![image](/assets/2025-12-05/peakboard-masked-parameter-input.png)

## Add a multi-line text parameter

Finally, let's create a multi-line text parameter. These parameters are typically used for long code-like text. For example, SQL statements or JSON / XML fragments.

Multi-line text is not a unique data type. Instead, a multi-line text parameter is a variant of a text parameter. To turn a text parameter into a multi-line text parameter, we set the `TypeDefinition` attribute `multiLine` to `true`:

{% highlight csharp %}
new CustomListPropertyDefinition { Name = "MultilineDescription", 
      Value = "Please provide\nsome\nbeautiful SQL", TypeDefinition = TypeDefinition.String.With(multiLine: true) }
{% endhighlight %}

Here's what it looks like in Peakboard Designer:

![image](/assets/2025-12-05/peakboard-multiline-parameter.png)

## Result

Defining the parameters of a data source is essential to creating a good user experience. The data types you choose and the parameter validation you do can really affect how easy your data source (and extension, in general) is to work with.

In the next part of this series, we'll explain how to build functions that can be used in both LUA scripts and Building Blocks: [Part III - Custom-made Functions](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Fun-with-Functions.html).