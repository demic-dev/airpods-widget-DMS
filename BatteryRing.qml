import QtQuick
import QtQuick.Shapes
import qs.Common
import qs.Widgets

// Circular battery indicator: a track ring with a coloured progress arc and the
// level (or a dash when unavailable) in the centre. Matches the popout mockup's
// conic-gradient rings.
Item {
    id: root

    property int level: -1               // 0..100, or -1 when the component is unavailable
    property bool charging: false
    property color ringColor: Theme.primary
    property color trackColor: Theme.withAlpha(Theme.surfaceText, 0.14)

    readonly property bool available: level >= 0
    readonly property real strokeW: 5
    readonly property real radius: (width - strokeW) / 2

    implicitWidth: 58
    implicitHeight: 58

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: false

        // Track (full circle)
        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.strokeW
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
                startAngle: -90
                sweepAngle: 360
            }
        }

        // Progress arc
        ShapePath {
            strokeColor: root.ringColor
            strokeWidth: root.strokeW
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.radius
                radiusY: root.radius
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

    // Centre label
    Item {
        anchors.centerIn: parent
        width: parent.width * 0.72
        height: width

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
            text: root.available ? root.level : "—"
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.DemiBold
            color: root.available ? Theme.surfaceText : Theme.surfaceVariantText
        }
    }
}
