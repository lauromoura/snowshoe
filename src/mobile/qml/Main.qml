import QtQuick 2.0
import "UiConstants.js" as UiConstants

Rectangle {
    id: rootPage
    width: UiConstants.PortraitWidth
    height: UiConstants.PortraitHeight
    color: "#aaa"
    clip: true

    Image {
        anchors.fill: parent
        source: "qrc:///mobile/app/bg_image"
    }

    PanelToggle {
        id: panelToggle
        anchors.top: parent.top
        anchors.topMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        navigationEnabled: navigationPanel.hasOpennedTabs
        onTopSitesSelected: {
            rootPage.state = "favorites";
        }
        onTabsSelected: {
            rootPage.state = "navigation";
        }
    }

    FavoritesPanel {
        id: favoritesPanel
        anchors.centerIn: parent
    }

    NavigationPanel {
        id: navigationPanel
        anchors.fill: parent

        onHasOpennedTabsChanged: {
            if (navigationPanel.hasOpennedTabs)
                rootPage.state = "favorites";
        }

        onWebViewMaximized: {
            rootPage.state = "navigationFullScreen";
        }
        onWebViewMinimized: {
            rootPage.state = "navigation";
        }

    }

    Image {
        id: plusButton
        source: ":/mobile/button_plus"
        width: 56
        height: 57

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: rootPage.horizontalCenter

        MouseArea {
            anchors.fill: parent
            onClicked: {
                urlBar.previousUrl = ""
                rootPage.state = "typeNewUrl"
            }
        }
    }

    Rectangle {
        id: urlArea
        color: "white"
        opacity: 0
        anchors {
            top: rootPage.top
            left: rootPage.left
            right: rootPage.right
            bottom: rootPage.bottom
        }

        Item {
            id: urlBarBackground
            height: 114
            anchors {
                bottom: urlArea.bottom;
                left: urlArea.left;
                right: urlArea.right;
            }

            Image {
                source: "qrc:///mobile/urlbar_bg_typing"
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            }

            UrlBar {
                id: urlBar
                height: 60
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: 15; rightMargin: 15 }
                property string previousUrl: ""
                verticalAlignment: TextInput.AlignVCenter
                input.focus: false

                onAccepted: {
                    navigationPanel.createTab(UrlTools.fromUserInput(urlBar.text));
                    urlBar.text = ""
                }

                Image {
                    source: "qrc:///mobile/button_icon_cancel"
                    visible: urlBar.text != ""
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: urlBar.text = ""
                    }
                }
            }
        }

        Image {
            id: fadingShadow
            source: "qrc:///mobile/urlbar_bg_browsing"
            anchors { left: parent.left; right: parent.right; bottom: urlBarBackground.top }
        }

        UrlSuggestions {
            id: urlSuggestions
            width: rootPage.width
            anchors { top: urlArea.top; bottom: urlBarBackground.top; left: urlArea.left; right: urlArea.right; bottomMargin: 1 }
            onSuggestionSelected: urlBar.text = suggestedUrl
            onSearchSelected: {
                var searchUrl = "http://www.google.com/search?q=" + urlBar.text.replace(" ", "+")
                navigationPanel.createTab(searchUrl)
                urlBar.text = ""
            }
            // Only lookup suggestions once you have at least 2 characters to provide better results.
            opacity: urlBar.text != urlBar.previousUrl && urlBar.text.length >= 2 ? 1 : 0
        }
    }

    state: "splash"
    states: [
        State {
            name: "splash"
            AnchorChanges { target: panelToggle; anchors.bottom: parent.top; anchors.top: undefined }
            PropertyChanges { target: favoritesPanel; visible: false }
            PropertyChanges { target: navigationPanel; visible: false }
            AnchorChanges { target: plusButton; anchors.bottom: undefined; anchors.top: parent.bottom }
            PropertyChanges { target: plusButton; opacity: 1 }
        },
        State {
            name: "favorites"
            PropertyChanges { target: plusButton; opacity: 1 }
            PropertyChanges { target: navigationPanel; visible: false }
            PropertyChanges { target: favoritesPanel; visible: true } // Note: this is redundant but needed for N9.
        },
        State {
            name: "navigation"
            PropertyChanges { target: plusButton; opacity: 1 }
            PropertyChanges { target: favoritesPanel; visible: false }
            PropertyChanges { target: navigationPanel; visible: true } // Note: this is redundant but needed for N9.
        },
        State {
            name: "navigationFullScreen"
            PropertyChanges { target: favoritesPanel; visible: false }
            PropertyChanges { target: navigationPanel; visible: true }  // Note: this is redundant but needed for N9.
            AnchorChanges { target: panelToggle; anchors.bottom: parent.top; anchors.top: undefined }
            StateChangeScript { script: panelToggle.resetToTabs() }
            AnchorChanges { target: plusButton; anchors.bottom: undefined; anchors.top: parent.bottom }
        },
        State {
            name: "typeNewUrl"
            AnchorChanges { target: panelToggle; anchors.bottom: parent.top; anchors.top: undefined }
            PropertyChanges { target: favoritesPanel; visible: false }
            PropertyChanges { target: navigationPanel; visible: false }
            AnchorChanges { target: plusButton; anchors.bottom: undefined; anchors.top: parent.bottom }
            PropertyChanges { target: urlBar; input.focus: true; displayHint: urlBar.text == "" }
            PropertyChanges { target: urlArea; opacity: 1 }
        }
    ]

    transitions: [
        Transition {
            from: "splash"
            AnchorAnimation { duration: 200; easing.type: Easing.InOutQuad }
        },
        Transition {
            to: "typeNewUrl"
            PropertyAnimation { properties: "opacity"; duration: 300 }
            SequentialAnimation {
                PropertyAction { target: plusButton; properties: "visible" }
                AnchorAnimation { duration: 300; easing.type: Easing.InOutQuad }
                PropertyAnimation { properties: "width"; duration: 300; easing.type: Easing.InOutQuad }
                PropertyAction { properties: "visible,focus" }
            }
        },
        Transition {
            from: "typeNewUrl"
            to: "navigationFullScreen"
            SequentialAnimation {
                PropertyAnimation { properties: "x,y,width,scale,opacity"; duration: 300; easing.type: Easing.InOutQuad }
                AnchorAnimation { duration: 0 }
            }
        },
        Transition {
            from: "navigation"
            to: "navigationFullScreen"
            reversible: true
            SequentialAnimation {
                AnchorAnimation { targets: [plusButton, panelToggle]; duration: 300 }
                PropertyAction { properties: "opacity" }
            }
        }
    ]

    Timer {
        running: true
        interval: 800
        onTriggered: rootPage.state = "favorites"
    }
}
