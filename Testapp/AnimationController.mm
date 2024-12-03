//
//  AnimationController.m
//  testapp
//
//  Created by Dmitry Lavrov on 03/12/2024.
//

#import "AnimationController.h"

AnimationController::AnimationController() {
}

void AnimationController::injectControlScript(CefRefPtr<CefBrowser> browser) {
    if (browser) {
        browser->GetMainFrame()->ExecuteJavaScript(
            controlScript,
            browser->GetMainFrame()->GetURL(),
            0);
    }
}

void AnimationController::setTotalFrames(CefRefPtr<CefBrowser> browser, int frames) {
    if (browser) {
        std::string script = "window.__animationController.setTotalFrames(" + std::to_string(frames) + ");";
        browser->GetMainFrame()->ExecuteJavaScript(
            script,
            browser->GetMainFrame()->GetURL(),
            0);
    }
}

void AnimationController::seekToFrame(CefRefPtr<CefBrowser> browser, int frame) {
    if (browser) {
        std::string script = "window.__animationController.seekToFrame(" + std::to_string(frame) + ");";
        browser->GetMainFrame()->ExecuteJavaScript(
            script,
            browser->GetMainFrame()->GetURL(),
            0);
    }
}

void AnimationController::play(CefRefPtr<CefBrowser> browser) {
    if (browser) {
        browser->GetMainFrame()->ExecuteJavaScript(
            "window.__animationController.play();",
            browser->GetMainFrame()->GetURL(),
            0);
    }
}

void AnimationController::pause(CefRefPtr<CefBrowser> browser) {
    if (browser) {
        browser->GetMainFrame()->ExecuteJavaScript(
            "window.__animationController.pause();",
            browser->GetMainFrame()->GetURL(),
            0);
    }
}
