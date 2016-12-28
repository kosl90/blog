# Introduction

Shadow DOM is one of the four Web Component standards:
1. HTML Templates
2. Shadow DOM
3. Custom elements
4. HTML Imports

It brings solutions for common problems in web development:
- Isolated DOM
- Scoped CSS
- Composition
- Simplifies CSS
- Productivity tool
  

Shadow DOM is just normal DOM with two differences:
1. how it's created/used
2. how it behaves in relation to the rest of the page.

Normally, you create DOM nodes and append them as children of another element.
With shadow DOM, you create a scoped DOM tree that's attached to the element,
but separate from its actual children. This scoped subtree is called a **shadow
tree**. The element it's attached to is its **shadow host**. Anything you add
in the shadows becomes local to the hosting element, including \<style\>. This is
how shadow DOM achieves CSS style scoping.

**shadow root** is a document fragment4 that gets attached to a "host" element.

~~~JavaScript
const header = document.createElement("header");
const shadowRoot = header.attachShadow({mode:"open"});
shadowRoot.innerHTML = "<h1>Hello Shadow DOM</h1>"; // could also use appehdChild

// header.shadowRoot === shadowRoot
// shadowRoot.host === header
~~~

# creating shadow DOM for a custom element
Shadow DOM is particularly useful when creating custom elements.

element's shadow DOM is rendered in place of its children. If you want to
display the children, you need to tell the browser where to render them by
placing a _<slot> element_ in you shadow DOM.


# Composition and slots

## Light DOM
The markup a user of you component writes. This DOM lives outside the component's
shadow DOM. It's the element's actual children.

~~~HTML
<button is="better-button">
  <!-- the image and span are better-button's light DOM -->
  <img src="gear.svg" slot="icon">
  <span>Settings</span>
</button>
~~~

## Shadow DOM
The DOM a component author writes. Shadow DOM is local to the component and
defines its internal structure, scoped CSS, and encapsulates your implpmentation
details. It can also define how to render markup that's authored by the consumer
of your component.

~~~HTML
<!-- #shadow-root -->
  <style>/* ... */</style>
  <slot name="icon"></slot>
  <span id="wrapper">
    <slot>Button</slot>
  </span>
~~~

## Composed DOM

The result of the browser distributing the user's light DOM into your shadow
DOM, rendering the final product. The composed tree is what you ultimately see
in the DevTools and what's rendered on the page.

~~~HTML
<button is="better-button">
  #shadow-root
    <style>/* ... */</style>
    <slot name="icon">
      <img src="gear.svg" slot="icon">
    </slot>
    <slot>
      <span>Settings</span>
    </slot>
</button>
~~~

# The <slot> element
Shadow DOM composes different DOM trees together using the <slot> element. **
Slots are placeholders inside your component that users can fill with their own
markup**. By defining one or more slots, you invite outside markup to render in
your component's shadow DOM. Essentially, you're saying "Render the user's
over here".

Elements are allowed to "cross" the shadow DOM boundary when a _<slot>_ invites
them in. These elements are called **distributed nodes**. Slots don't physically
move DOM; they render it at another location inside the shadow DOM.

A component can define zero or more slots in its shadow DOM. Slots can be empty
or provide fallback content. If the user doesn't provide _light DOM_ content,
the slot renders its fallback content.

~~~HTML
<!-- Default slot. If there's more than one default slot, the first is used. -->
<slot></slot>

<slot>Fancy button</slot> <!-- default slot with fallback content -->

<slot> <!-- default slot entire DOM tree as fallback -->
  <h2>Title</h2>
  <summary>Description text</summary>
</slot>
~~~


# Styling

A component that uses shadow DOM can be styled by the main page, define its own
styles, or provide hooks (in the form of (CSS custom properties)[]) for users to
override defaults.

Hands down the most useful feature of shadow DOM is **scoped CSS**:

- CSS selectors from the outer page don't apply inside your component.
- Styles defined inside don't bleed out. They're scoped to the host element.

**CSS selectors used inside shadow DOM apply locally to your component**.

Web components can style themeselves too, by using _:host_ selector. The
functional form of _:host(<selector>)_ allows you to target the host if it
matches a <selector>. This is a great way to for your component to enscapsulate
behaviours that react to user interaction or state or style internal nodes based
on the host.

_:host-context(<selector>)_ matches the component if it or any of its ancestors
matches <selector>. A common use for this is theming based on a component's
surroundings. For example, many people do theming by appying a class to \<html\>
or \<body\>.
~~~HTML
<body class="darktmeme">
  <fancy-tabs>
  <!-- ... -->
  </fancy-tabs>
</body>
~~~

~~~CSS
:host-context(.darktheme) {
  color: white;
  background: black;
}
~~~

_:host-context_ can be useful for theming, but an even better approcach is
**create style hooks using CSS custom properties**.

# Styling distributed nodes

::slotted(<compound-selector>) matches nodes that are distributed into a \<slot\>.

~~~HTML
<name-badge>
  <h2>Eric Bidelman</h2>
  <span class="title">
    Digital Jedi, <span class="company">Google</span>
  </span>
</name-badge>
~~~

~~~CSS
::slotted(h2) {
  margin: 0;
  font-weight: 300;
  color: red;
}
::slotted(.title) {
  color: orange;
}

/* DOESN'T WORK (can only select top-level nodes).
::slotted(.company),
::slotted(.title .company) {
  text-transform: uppercase;
}
*/
~~~

**Styles that applied before distribution continue to apply after distribution**.
However, when the light DOM is distributed, it can take on additional styles.


# Styling a component from the outside

The easiest way is to use the tag name as a selector. Outside styles always win
over styles defined in shadow DOM.

> As the componeht author, you're responsible for letting developers know about
> CSS custom properties they can use. Consider it part of your component's
> public interface. Make sure to document styling hooks!


# Creating closed shadow roots (should avoid)

In "close" mode, outside JavaScript won't be able to access the internal DOM of
your component.

> Closed shadow roots are not very useful. Some developers will see closed mode
> as an artificial security feature. But let's be clear, it's **not** a security
> feature. Closed mode simply prevents outside JS from drilling into an element's
> internal DOM.

Here's my summary of why you should never create web components with `{mode: 'close'}`:

1. Artificial sense of security. There's nothing stopping an attacker from
  hijacking `Element.prototype.attachShadow`.
2. Closed mode **prevents your custom element code from accessing its own shadow
  DOM**.
3. **Closed mode makes your component less flexible for end users**.


# Working with slots in JS

## slotchange
`slotchange` event fires when a slot's distributed nodes changes. For example,
if the user adds/removes children from the light DOM.
  **NOTE**: `slotchange` does not fire when an instance of the component is first
  initialized.
To moitor other types of changes to light DOM, you can setup a MutationObserver
in your element's constructor.

## what elements re being rendering in a slot

`slot.assignedNodes({flatten: true}?)`

# Using custom events

Custom DOM events which are fired on internal nodes in a shadow tree do not
buttle out of the shadow boundary unless the event is created using the `composed: true`
flag:
~~~JavaScript
selectTab() {
  const tabs = this.shadowRoot.querySelector("#tabs");
  tabs.dispatchEvent(new Event("tab-select", {bubbles: true, composed: true}));
}
~~~

# tip and tricks

## finding all the custom elements used by a page
~~~JavaScript
const allCustomElements = [];
function isCustomEement(el) {
  const isAttr = el.getAttribute("is");
  // Check for <super-button> and <button is="super-button">.
  return el.localName.includes('-') || isAttr && isAttr.includes('-');
}

function findAllCustomElements(nodes) {
  for (let i = 0, el; el = nodes[i]; ++i) {
    if (isCustomEement(el)) {
      allCustomElements.push(el);
    }

    // If the element has shadow DOM, dig deeper.
    if (el.shadowRoot) {
      findAllCustomElements(el.shadowRoot.querySelectorAll('*'));
    }
  }
}

findAllCustomElements(document.querySelectorAll('*'));
~~~


## To feature detect shadow DOM, check for the existence of attachShadow:
~~~JavaScript
function supportShadowDOM() {
  return !!HTMLElement.prototype.attachShadow;
}
if (supportShadowDOM()) {
  // Good to go!
} else {
  // Use polyfills
}
~~~
