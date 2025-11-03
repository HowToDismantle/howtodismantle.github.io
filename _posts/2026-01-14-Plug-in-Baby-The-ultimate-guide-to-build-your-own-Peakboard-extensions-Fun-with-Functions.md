---
layout: post
title: Plug-in, Baby - The Ultimate Guide to Building Your Own Peakboard Extensions - Fun with Functions
date: 2023-03-01 00:00:00 +0000
tags: dev
image: /assets/2026-01-14/title.png
image_header: /assets/2026-01-14/title.png
bg_alternative: true
read_more_links:
  - name: Other developer articles
    url: /category/dev
downloads:
  - name: Source code for this article
    url: https://github.com/HowToDismantle/howtodismantle.github.io/tree/main/assets/2026-01-14/MeowExtension
  - name: ExtensionCalls.pbmx
    url: /assets/2025-11-03/ExtensionCalls.pbmx
---
In the first part of the series we learned how to build the frame of a Peakboard extension. We used two classes to provide both metadata and the actual payload that is exchanged between the extension and the Peakboard application. In the second part we discussed how to form parameters to enable user interaction and let the user configure the extension. Here's an overview of this article series:

* [Part I - The Basics](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-The-Basics.html)
* [Part II - Parameters and User Input](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Parameters-and-User-Input.html)
* [Part III - Custom-made Functions](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Fun-with-Functions.html)
* [Part IV - Event-triggered data sources](/Plug-in-Baby-The-ultimate-guide-to-build-your-own-Peakboard-extensions-Event-triggered-data-sources.html)

In today's article we will talk about how to add functions to the extensions. A function of a data source is usually used to interact with the data source beside the pure query for data. Let's assume we build an extension for autonomous robots. So we build a data source to query the position of the robots and refresh it every couple of seconds. Let's assume we want the user to use our Peakboard application to command the robot to navigate to the charging station; we would add a `GoToChargingStation` function to our robot extension.
Understanding the foundation we discussed in the first and second part of the series is a crucial requirement. The sample code used in this article can be found at [github](https://github.com/HowToDismantle/howtodismantle.github.io/tree/main/assets/2026-01-14/MeowExtension).

## Create a simple function with a return parameter

To understand the principles behind function development, we will set up a function that receives two numbers as parameters, summarizes them and returns the result to the caller. During extension development we must add the metadata of our new function during `GetDefinitionOverride()` to define this function. The source code shows how to do that. We just provide an object defining the function to the `Functions` attribute of the `CustomListDefinition` instance:

{% highlight csharp %}
protected override CustomListDefinition GetDefinitionOverride()
{
    return new CustomListDefinition
    {
        ID = "CatCustomList",
        Name = "Cat List",
        Description = "A custom list for cats with breed and age information",
        PropertyInputPossible = true,
        PropertyInputDefaults = { new CustomListPropertyDefinition { Name = "CatsName", Value = "" } },
        Functions = new CustomListFunctionDefinitionCollection
        {
            new CustomListFunctionDefinition
            {
                Name = "AddMyNumbers",
                Description = "Adds two numbers",
                InputParameters = new CustomListFunctionInputParameterDefinitionCollection
                {
                    new CustomListFunctionInputParameterDefinition
                    {
                        Name = "FirstNumber",
                        Type = CustomListFunctionParameterTypes.Number,
                        Description = "The first number to be added"
                    },
                    new CustomListFunctionInputParameterDefinition
                    {
                        Name = "SecondNumber",
                        Type = CustomListFunctionParameterTypes.Number,
                        Description = "The first number to be added"
                    }
                },
                ReturnParameters = new CustomListFunctionReturnParameterDefinitionCollection
                {
                    new CustomListFunctionReturnParameterDefinition
                    {
                        Name = "Result",
                        Type = CustomListFunctionParameterTypes.Number,
                        Description = "The result of the addition"
                    }
                }
            }
        }
    };
}
{% endhighlight %}

When an extension list has one or more functions defined, the override `ExecuteFunctionOverride` is called when the host system wants to trigger the function. All parameters are provided as part of the `data` object. The return value, in our case the result of the mathematical calculation, is added to the return context object of the class `CustomListExecuteReturnContext`.

{% highlight csharp %}
protected override CustomListExecuteReturnContext ExecuteFunctionOverride(CustomListData data, CustomListExecuteParameterContext context)
{
    if (context.FunctionName.Equals("AddMyNumbers", StringComparison.InvariantCultureIgnoreCase))
    {
        Double FirstNumber = (Double)context.Values[0].GetValue();
        Double SecondNumber = (Double)context.Values[1].GetValue();

        var returncontext = new CustomListExecuteReturnContext();
        returncontext.Add(FirstNumber + SecondNumber);   

        return returncontext;
    }
    else
    {
        throw new DataErrorException("Function is not supported in this version.");
    }
}
{% endhighlight %}

After implementing and deploying the extension, an additional Building Block shows up in the Peakboard designer's code editor. It lets us call any function that is provided by an extension just by selecting the data source. The metadata is automatically used to build the Building Block, so we can just add the two values to be processed and then use the return value to write it to a text control.

![Peakboard Building Block calling the custom function](/assets/2026-01-14/peakboard-custom-function-building-block.png)

## Submitting a complex parameter to an extension function

The values we used to exchange with the extension have been scalar and simple. Let's assume we want to submit a table-like value to the extension function. In our sample our table is supposed to be a list of messages, along with their message type, to be written to a message logger.

For this use case we use `CustomListFunctionParameterTypes.Collection` as parameter type for the definition of the function's metadata. Here's the source code to be added during `GetDefinitionOverride`.

{% highlight csharp %}
new CustomListFunctionDefinition
{
    Name = "PrintMyTableToLog",
    InputParameters = new CustomListFunctionInputParameterDefinitionCollection
    {
        new CustomListFunctionInputParameterDefinition
        {
            Name = "MessageTable",
            Type = CustomListFunctionParameterTypes.Collection,
            Description = "A table containing messages"
        }
    }
},
{% endhighlight %}

For the `ExecuteFunctionOverride` we just use `.CollectionValue` to convert the parameter object into an instance of `CustomListObjectElementCollection` and iterate through it...

{% highlight csharp %}
else if (context.FunctionName.Equals("PrintMyTableToLog", StringComparison.InvariantCultureIgnoreCase))
{
    CustomListObjectElementCollection MyTab = context.Values[0].CollectionValue;

    foreach(CustomListObjectElement row in MyTab)
    {
        this.Log.Info($"{row["MessageType"]}: {row["Message"]}");
    }

    return new CustomListExecuteReturnContext();
}
{% endhighlight %}

On the host side we can't use Building Blocks anymore because, as of early 2026, complex parameters are not yet supported by the Building Blocks. So to use this function we need to switch to LUA coding. The sample shows how to create the table-like object, store data in it and submit it as a parameter to the function of the extension data source.

![LUA script building the table parameter for the extension function](/assets/2026-01-14/lua-table-parameter-function.png)

The screenshot shows the test cockpit in action. The above code is generating the log file entries through the extension.

![Peakboard test cockpit showing log entries generated by the extension](/assets/2026-01-14/peakboard-test-cockpit-logging.png)

## Returning multiple values

In the first example we used a simple, single, scalar return parameter. Lets assume things get more complicated and we need more than one return value. In this case we can use the same trick we already used in the second example. During the construction of the function we mark the return value as type `CustomListFunctionParameterTypes.Object` to allow a more complex data transfer.

{% highlight csharp %}
new CustomListFunctionDefinition
{
    Name = "GetACat",
    ReturnParameters = new CustomListFunctionReturnParameterDefinitionCollection
    {
        new CustomListFunctionReturnParameterDefinition
        {
            Name = "Result",
            Type = CustomListFunctionParameterTypes.Object,
            Description = "A cat object is returned"
        }
    }
}
{% endhighlight %}

Let's have a look at the actual function implementation in `ExecuteFunctionOverride`. We just build a `CustomListObjectElement` instance, which represents a single table row, or to be more precise, a key/value pair collection.

{% highlight csharp %}
else if (context.FunctionName.Equals("GetACat", StringComparison.InvariantCultureIgnoreCase))
{
    var item = new CustomListObjectElement();
    item.Add("Name", "Tom");
    item.Add("Age", 7);

    var returncontext = new CustomListExecuteReturnContext();
    returncontext.Add(item);

    return returncontext;
}
{% endhighlight %}

We switch over to the host side. Here's the LUA code to process this complex object. It's just a generic LUA object that accepts the attributes to be addressed by their key name directly without any hassle. By the way: we can even return table-like objects. In that case we would have to use `CustomListObjectElementCollection` like in the second example.

![LUA script reading the complex return object](/assets/2026-01-14/lua-handle-complex-return.png)

Here's the script in action using the example test cockpit.

![Peakboard test cockpit showing the complex return value](/assets/2026-01-14/peakboard-test-cockpit-return.png)

## Conclusion

Extension functions are super easy to understand and implement once we understand the principle behind it. Even complex parameters like key/value collections or even tables can be exchanged.



