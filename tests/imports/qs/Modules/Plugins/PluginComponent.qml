import QtQuick

// Only the DMS integration boundary is mocked; plugin components are real.
Item {
    property var pluginData: ({})
    property var pluginService: null
    property string pluginId: ""
    property real barThickness: 48
    property real widgetThickness: 30
    property real iconSize: 20
    property var barConfig: null
    property Component horizontalBarPill
    property Component verticalBarPill
    property Component popoutContent
    property real popoutWidth: 0
    property real popoutHeight: 0
    property string ccWidgetIcon: ""
    property string ccWidgetPrimaryText: ""
    property string ccWidgetSecondaryText: ""
    property bool ccWidgetIsActive: false
    property real ccDetailHeight: 0
    property Component ccDetailContent
    property bool effectiveVisible: true
    signal ccWidgetToggled
    function setVisibilityOverride(visible) { effectiveVisible = visible; }
}
