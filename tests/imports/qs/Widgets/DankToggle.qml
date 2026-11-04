import QtQuick

Item {
    property bool hideText: true
    property bool checked: false
    signal toggled(bool value)
    implicitWidth: 48
    implicitHeight: 28
}
