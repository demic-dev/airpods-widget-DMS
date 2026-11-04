pragma Singleton
import QtQuick

QtObject {
    readonly property color primary: "#65c86c"
    readonly property color primaryText: "#000000"
    readonly property color primaryContainer: "#204826"
    readonly property color surfaceText: "#ffffff"
    readonly property color surfaceVariantText: "#cccccc"
    readonly property color surfaceContainerHigh: "#252925"
    readonly property color surfaceContainerHighest: "#454945"
    readonly property color warning: "#ff8800"
    readonly property color outline: "#888888"
    readonly property int spacingXS: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 16
    readonly property int iconSize: 24
    readonly property int iconSizeLarge: 32
    readonly property int cornerRadius: 12
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 18
    readonly property int shortDuration: 0
    function withAlpha(color, alpha) { return Qt.rgba(color.r, color.g, color.b, alpha); }
    function barIconSize(thickness, offset, maximize, scale) { return 20; }
}
