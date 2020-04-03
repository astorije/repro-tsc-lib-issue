# Dependencies referencing `lib`s silence the TypeScript checker

First, make sure [Node.js](https://nodejs.org/en/) and [Yarn](https://yarnpkg.com/) are installed.

Then, run `./build-all.sh`.

In both `expected` and `actual` projects:

- The compilation `target` is set to `es2015` and no `lib`s are specified. According to the [TypeScript docs](https://www.typescriptlang.org/docs/handbook/compiler-options.html), it means the following libraries are loaded by default: `DOM`, `ES6`, `DOM.Iterable`, `ScriptHost`.
- The code in `index.js` uses `Object.values` (which is a ES2017 feature) and `BigInt` (which is a ES2020 feature).

The only difference between the 2 projects is that `actual` has a (direct) dependency on `@types/node`.

## Building the `expected` project

When building the `expected` project, we get the following 2 errors:

```ts
$ tsc
index.ts:2:20 - error TS2339: Property 'values' does not exist on type 'ObjectConstructor'.

2 console.log(Object.values({ foo: BigInt(42) }));
                     ~~~~~~

index.ts:2:34 - error TS2304: Cannot find name 'BigInt'.

2 console.log(Object.values({ foo: BigInt(42) }));
                                   ~~~~~~

Found 2 errors.
```

This is expected because neither the `es2017`, `es2020`, `esnext`, etc. `lib`s are included in the compilation.

## Building the `actual` project

However, when building the `actual` project, none of these errors pop up:

```ts
$ tsc
✨  Done in 1.89s.
```

This is because the `@types/node` dependency contains 2 files ([this one](https://github.com/DefinitelyTyped/DefinitelyTyped/blob/master/types/node/ts3.5/index.d.ts#L4-L7) and [that one](https://github.com/DefinitelyTyped/DefinitelyTyped/blob/master/types/node/ts3.2/index.d.ts#L4-L7)) that reference `es2018` and `esnext.bigint`, which in turn references `es2017`.

Those libs then get implicitly added to the compilation.

_Note that running `tsc` and `tsc --build` produces the same thing here._

## The problem

Imagine you am building a project for the browser, with an explicit target of `es2015`. By not including extra libraries, you rely on the type checker to barf if you use features not supported in ES2015.

However, one of your dependencies might be referencing to any `lib` using a [triple-slash directives](https://www.typescriptlang.org/docs/handbook/triple-slash-directives.html) and therefore break browser compatibility without the type checker informing you.

Of course, in this repository, one might just remove the dependency to `@types/node`. But in practice, this is widely used, probably by one of your dependencies without you even knowing it.
For example, the `@sindresorhus/is` package is [making such reference](https://github.com/sindresorhus/is/blob/master/source/index.ts#L1-L3), and this package is used [_a lot_](https://github.com/sindresorhus/is/network/dependents?package_id=UGFja2FnZS00Njc3NjI1ODQ%3D).

In our cases, we use `apollo-cache-inmemory`, `enzyme` (and `@types/enzyme`), and `got`, all of which have a dependency on `@types/node`. Using the [`yarn why`](https://classic.yarnpkg.com/en/docs/cli/why/) on one of our projects, I get the following nested dependencies:

```
@types/enzyme > @types/cheerio > @types/node
apollo-cache-inmemory > optimism > @wry/context > @types/node
enzyme > cheerio > parse5 > @types/node
got > @types/cacheable-request > @types/node
got > @types/cacheable-request > @types/keyv > @types/node
got > @types/cacheable-request > @types/responselike > @types/node
```

To see this in action, the [`apollo-cache-inmemory`](https://github.com/astorije/repro-tsc-lib-issue/tree/apollo-cache-inmemory) branch demonstrates the issue as well.

## The solution

I am opening this reproduction repository because I am not sure how to solve this issue at the moment. I will update this repository with related links as I find out solutions.

In the meantime, I will be using [`eslint-plugin-es`](https://eslint-plugin-es.mysticatea.dev/) to report features that should not be used and that the TypeScript checker did not error on.

## Environment

```
$ node --version
v12.14.0
$ yarn --version
1.22.4
```
