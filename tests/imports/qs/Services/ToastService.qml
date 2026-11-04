pragma Singleton
import QtQuick

QtObject {
    property string message: ""
    function showInfo(text) { message = text; }
}
