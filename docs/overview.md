---
title: "MDI R Package"
has_children: false
nav_order: 0
---

{% include mdi-project-overview.md %} 

This is the documentation for the **MDI manager**,
delivered in the form of an **R package**.
It will help you install and run the MDI on your server,
desktop, or laptop computer. Functions initialize Stage 1 pipeline
execution and help launch the Stage 2 web apps.

### Other ways to call the MDI R functions

While the MDI R package is at the heart of many installations
and is required to run Stage 2 Apps, many users will never install it or
use its functions directly as they are accessed 
by other scripts and utilities, including:

- MDI Desktop: <https://midataint.github.io/mdi-desktop-app>
- MDI command line utility: <https://github.com/MiDataInt/mdi.git>

In particular, the MDI Desktop is the recommended way to run
most Stage 2 apps. However, if you prefer, you can `install()` 
and `run()` the MDI from within R.

{% include mdi-project-documentation.md %}
