
sv-tabs-js
=================================================

**sv-tabs-js** is a vanilla JavaScript plugin for displaying tabs.

HTML structure:

```html
<div class="sv-tabs-wrapper">
	<nav class="sv-tabs-tab-list">
		<a class="sv-tabs-tab active" href="#tab1">Tab 1</a>
		<a class="sv-tabs-tab" href="#tab2">Tab 2</a>
	</nav>
	<div class="sv-tabs-panel-list">
		<div class="sv-tabs-panel active" id="tab1">Tab 1 content.</div>
		<div class="sv-tabs-panel" id="tab2">Tab 2 content.</div>
	</div>
</div>
```

JavaScript:

```js
var tabBlocks = document.querySelector('.sv-tabs-wrapper');
var svTabs = new SV.Tabs(tabBlocks, {useAnchors: true});
```

See `example.html` for a demo. A few notes:

- The first tab in the list will automatically be set to be active initially. However, it's recommended to add the "active" class to the HTML if possible (tab and panel), to avoid FOUT (Flash Of Unactivated Tabs).
- The anchor link on a tab must target an ID of one of the panels, i.e. `<a href="#mytabname">` would target `<li id="mytabname">`.
- The panels can appear in any order in the source. The anchor will show the tab with the corresponding ID, wherever it is.
- The `useAnchors` option will add "hashtag anchors" to the URL, and load the appropriate tab when the page is reloaded or the users navigates away then comes back. Pass `{useAnchors: true}` in the options parameter to use it.
- The `equalHeight` option will set all tabs to be the same height; this prevents subsequent content from shifting up and down when tabs are clicked. Pass `{equalHeight: true}` in the options parameter to use it.
- The plugin currently has 1 method, `showTab` which manually shows a particular tab given its ID, e.g. `svTabs.showTab('tab2')` in the above example.
- The CSS is generated from the Sass file `svtabs.scss`. Several variables are defined which can be overridden if importing the Sass file.
