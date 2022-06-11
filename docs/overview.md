---
title: "MDI R Package"
has_children: false
nav_order: 0
---

{% for page in site.pages %}
    {% if page.grand_parent %}
        {% for parent in site.pages %}
            {% if parent.title == page.parent %}
                {% assign parent_order = parent.nav_order | times: 100 %}
                {% for grandparent in site.pages %}
                    {% if grandparent.title == parent.parent %}
                        {% assign site_order = grandparent.nav_order | times: 10000 | plus: parent_order | plus: page.nav_order %}
                    {% endif %}
                {% endfor %}
            {% endif %}
        {% endfor %}
    {% elsif page.parent %}
        {% for parent in site.pages %}
            {% if parent.title == page.parent %}
                {% assign page_order = page.nav_order | times: 100 %}
                {% assign site_order = parent.nav_order | times: 10000 | plus: page_order %}
            {% endif %}
        {% endfor %}
    {% else %}
        {% assign site_order = page.nav_order | times: 10000 %}
    {% endif %}

--------------------------------------
title = {{ x.title }}  
parent = {{ x.parent }}  
grand_parent = {{ x.grand_parent }}  
nav_order = {{ x.nav_order }}  
site_order = {{ site_order }}  
absolute_url = {{ x.url | absolute_url }}  
relative_url = {{ x.url | relative_url }}  

{% endfor %}



{% include mdi-project-overview.md %}

This is the documentation for the **MDI manager** utility,
delivered in the form of an **R package**.
It will help you install and run the MDI on your server,
desktop or laptop computer. Functions initialize Stage 1 pipeline
execution and help launch the Stage 2 web apps.

### Other ways to call the MDI R functions

While the MDI R package is at the heart of most installations
and is required to run Stage 2 Apps, many users will never
use its R functions directly as they are called for
you by other scripts and utilities, including:

- MDI command line utility: <https://github.com/MiDataInt/mdi.git>
- MDI batch scripts: <https://wilsonte-umich.shinyapps.io/mdi-script-generator/>

However, if you prefer, you can <code>install()</code> and 
<code>run()</code> from within R.

{% include mdi-project-documentation.md %}
