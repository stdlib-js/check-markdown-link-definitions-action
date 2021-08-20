> A [broken link][broken-link] and a [working link][working-link].

Inline links such as [google.com](http://wrong-google-url.com) are not checked.

```javascript
/**
* Boop [beep][beep].
*
* [beep]: https://beep.com
* [beep]: https://beep.com
*
* @returns {string} a value
*
* @example
* var str = beep();
* // returns 'boop'
*/
function beep() {
    return 'boop';
}
```

[broken-link]: https://this-link-is-broken.com

[working-link]: https://github.com

[skipped-link]: https://github.com/stdlib-js/stdlib/tree/develop/lib/node_modules/%40stdlib/regexp/basename

[npm-code-of-conduct]: https://www.npmjs.com/policies/conduct

[git-history]: https://github.com/stdlib-js/stdlib/commits/master/CODE_OF_CONDUCT.md