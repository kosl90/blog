// 会撑起一定高度
<img src="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg'/>" />

// 不会撑起高度
<img src="data:image/gif;base64,R0lGODlhAQABAAAAACwAAAAAAQABAAA=">

!!be care of inline span.

1. container img { /* last child */
vertical-align: middle;
width: 0;
height: 100%;
}
2. container table {
display: inline-table; /* IE8 with DOCTYPE */
vertical-align: middle;
height: 100%; /* FIXME: box-sizing: content-box; ??? */
}
3. container {
display: table-cell; /* IE8 with DOCTYPE */
vertical-align: middle;
}
4. container {
display: flex;
align-items: center;
}
5. .item {
margin-top: 50%;
transform: translateY(-50%);
}


https://www.qianduan.net/css-to-achieve-the-vertical-center-of-the-five-kinds-of-methods/
https://tympanus.net/codrops/css_reference/vertical-align/
