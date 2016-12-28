# filter

TODO


# backdrop-filter

chrome://flags/#enable-experimental-web-platform-features


# order of graphical operations

followed [SVG compositing](http://www.w3.org/TR/SVG11/render.html#Introduction) model [SVG11](https://www.w3.org/TR/compositing-1/#biblio-svg11): filter | clipping | masking | blending | compositing

# background-blend-mode

blend mode for each background layer(`background-color`, `background-image`(including gradient)) of an element.


# mix-blend-mode

unlike `background-blend-mode` used for blending backgrounds, `mix-blend-mode` blends elements with their backdrop. Just like blending layers on .psd.


## source, destination and backdrop

Compositing defines how what you want to draw will be blended with what is already drawn on the canvas. The source is what you want to draw, and the destination is what is already drawn.

A backdrop is the content behind the source element and is what the element is composited with. The destination element is the element that lies behind the source element, and which the source overlaps with. The backdrop is the area where the color blending is done between the source and the destination. 

![source, destination and backdrop](https://sarasoueidan.com/images/backdrop.png)


# blend and stacking context

According to the specification, applying a blend mode other than `normal` to the element will establish a new stacking context on that element, forming a _group_. This group must then be blending applied, must blend with all the underlying content **_of the stacking context that that element blengs to_**. It will not blend with contents outside that context.

Any property that leads to the creation of a stacking context can hence affect blending.

Simply, blending can only affect the elements on the same stacking context.

~~~CSS
.container {
  width: 200px;
  height: 400px;
}
.container-1 img, container-2 img, container-3 img{
  max-width: 100%;
  mix-blend-mode: luminosity;
}
.container-2 {
  opacity: 0.8; /* trigger new stacking context */
}
.container-3 {
  opacity: .8;
  background: #fff;
}
~~~

~~~HTML
<div class='container container-2'>
<img src=''>
<h1>Text</h1>
</div>
~~~


# blend mode

- normal: default. no blending.
- multiply: 
- screen:
- overlay:
- darken: 
- lighten:
- color-dodge:
- color-burn:
- hard-light:
- soft-light:
- different:
- exclusion:
- hue:
- saturation:
- color:
- luminosity:


# isolation

The `isolation` property is used to isolate a group of elements so that they do not blend with their backdrop. If `background-blend-mode` property is used, the `isolation` property is not needed since background layers must not blend with
the content that is behind the element, instead they must act as if they are rendered into an isolated group (the element itself).


# ref
- https://webkit.org/blog/3632/introducing-backdrop-filters/
- http://www.w3cplus.com/css3/advanced-css-filters.html
- https://www.w3.org/TR/filter-effects/#intro
- \<blend mode\>: [http://tympanus.net/codrops/css_reference/blend-mode/](http://tympanus.net/codrops/css_reference/blend-mode/)
- background-blend-mode: http://tympanus.net/codrops/css_reference/background-blend-mode/
- mix-blend-mode: http://tympanus.net/codrops/css_reference/mix-blend-mode/
- isolation: http://tympanus.net/codrops/css_reference/isolation/
- CSS Blend Modes could be the next big thing in Web Design:https://medium.com/@bennettfeely/css-blend-modes-could-be-the-next-big-thing-in-web-design-6b51bf53743a#.94yujwlb4
- CSS Image Effects#1:http://una.im/vintage-washout/
- Basics of CSS Blend Modes:https://css-tricks.com/basics-css-blend-modes/
- Basics of CSS Blend Modes(中文翻译): http://www.w3cplus.com/css3/basics-css-blend-modes.html
- Compositing and Blending Level 1:https://www.w3.org/TR/compositing-1/#introduction
- Image Effects with CSS: http://bennettfeely.com/image-effects/
- Blend modes wikipedia: https://en.wikipedia.org/wiki/Blend_modes
