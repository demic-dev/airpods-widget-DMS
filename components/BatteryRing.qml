import QtQuick
import QtQuick.Shapes
import qs.Common
import qs.Widgets

Item {
    id: root

    property int level: -1
    property bool charging: false
    property color ringColor: Theme.primary
    property color trackColor: Theme.withAlpha(Theme.surfaceText, 0.14)
    readonly property bool available: level >= 0
    readonly property real strokeWidth: 5
    readonly property real ringRadius: Math.max(0, (width - strokeWidth) / 2)

    implicitWidth: 58
    implicitHeight: 58

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.ringRadius
                radiusY: root.ringRadius
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.ringColor
            strokeWidth: root.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.ringRadius
                radiusY: root.ringRadius
                startAngle: -90
                sweepAngle: root.available ? 360 * Math.max(0, Math.min(100, root.level)) / 100 : 0
                Behavior on sweepAngle {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    DankIcon {
        visible: root.charging && root.available
        anchors.centerIn: parent
        name: "bolt"
        filled: true
        size: Theme.iconSize - 6
        color: root.ringColor
    }

    StyledText {
        visible: !(root.charging && root.available)
        anchors.centerIn: parent
        text: root.available ? root.level : "-"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.DemiBold
        color: root.available ? Theme.surfaceText : Theme.surfaceVariantText
    }
}
