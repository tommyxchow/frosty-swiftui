# Frosty (SwiftUI)

**Note**: This app mainly served as a prototype and has been put on hold in favor of a new one built with Flutter. See it [here](https://github.com/tommyxchow/frosty), and if you're interested in why this decision was made, read below.

---

A [Twitch](https://www.twitch.tv/) client for iOS built with [SwiftUI](https://developer.apple.com/xcode/swiftui/) (and some UIKit).

<p float="left">
  <img src="Screenshots/top.PNG" width="32%">
  <img src="Screenshots/search2.PNG" width="32%">
  <img src="Screenshots/chat.PNG" width="32%">
</p>

## The Future of This App

Unfortunately, SwiftUI is currently not fit to support an effective Twitch chat. Until Apple releases performant layouts similar to span (HTML) or flex wrap, this app won't be able to achieve a consistent chat. The issues described next prevent this app from reaching its full potential and have made me put it on hold.

## Issues

### 1. Inline GIF emotes with text are not supported (i.e. span, wrap)

- When constructing a chat message containing various dynamic assets, each item (text, badges, emotes, and GIFs) is contained in a view.
- These views need to be placed horizontally and wrap when the container width is exceeded in order to emulate a properly formatted chat message.
- SwiftUI has the [HStack](https://developer.apple.com/documentation/swiftui/hstack) view layout, but it does not support wrapping. Inline images are supported but only static images, not GIFs, will work.
- FlexLayout was introduced as a workaround, but required the use of [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable), resulting in unforeseen side effects such as having to manually size the view by overriding the [intrinsicContentSize](https://developer.apple.com/documentation/uikit/uiview/1622600-intrinsiccontentsize). This would sometimes cause [chat messages to overlap each other](/Screenshots/glitch1.PNG) and [long strings of text to wrap in their own container](/Screenshots/glitch2.PNG).

### 2. GIF emotes don't sync

- Each view is created as a new instance, so GIFs will always start at their first frame when appearing.
- A possible workaround is to keep track of the current frame for each GIF and start from there, but again it's another workaround and would require a bit of overhead.

### 3. Emotes aren't sized correctly on their first appearance

- Since emotes first have to be fetched before being displayed and cached, there will be a blank placeholder image view until the image request is complete. Once the request is complete, the image will fill in the space of the placeholder.
- The placeholder image view can only have a predefined size, but with so many emotes having varying widths and heights they won't fit into the view perfectly. Once the emote, such as one that is very wide, is finally loaded and displayed, the emote will appear warped and smaller than anticipated.

These issues may be fixable, but would lead to a workaround-rabbit-hole that I've already gone far enough into. This led me to look into other mobile frameworks with iOS support, specifically [React Native](https://reactnative.dev/) and [Flutter](https://flutter.dev/).

## Other Frameworks

### React Native

While experimenting with React Native (RN), issues 1 and 2 persisted.  This was somewhat unsurprising as RN uses native components under the hood. Although RN does have [flex wrap](https://reactnative.dev/docs/flexbox#flex-wrap), span was still necessary to have elements truly inline with text. As a result, the prototype was promptly scrapped.

### Flutter

While working with Flutter, it was clear that the team wanted to bring web-specific behaviors to mobile. Features like TextSpan/WidgetSpan, synced GIFs, height-only image sizing, and more are core features of the framework.

Since I was trying to emulate the web Twitch chat experience on iOS, it made perfect sense to take advantage of these features. Having the app work identically on Android through the Skia engine was a neat bonus too.

## Dependencies

- [Nuke](https://github.com/kean/Nuke) & [NukeUI](https://github.com/kean/NukeUI)
  - Caches thumbnails, badges, and emotes.
- [FlexLayout](https://github.com/layoutBox/FlexLayout)
  - Lays out text and emote views with wrap and align.
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)
  - Stores user tokens securely.
- [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage)
  - Enables GIFs.
