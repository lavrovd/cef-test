//
//  AnimationController.h
//  testapp
//
//  Created by Dmitry Lavrov on 03/12/2024.
//

#pragma once

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "include/cef_browser.h"
#pragma clang diagnostic pop

class AnimationController {
public:
    AnimationController();
    
    void injectControlScript(CefRefPtr<CefBrowser> browser);
    void setTotalFrames(CefRefPtr<CefBrowser> browser, int frames);
    void seekToFrame(CefRefPtr<CefBrowser> browser, int frame);
    void play(CefRefPtr<CefBrowser> browser);
    void pause(CefRefPtr<CefBrowser> browser);
    
private:
    const char* controlScript = R"(
        window.__animationController = {
            frameRate: 60,
            totalFrames: 100,
            isPaused: false,
            
            initialize: function() {
                this.overrideAnimations();
                document.addEventListener('animationstart', () => this.overrideAnimations());
            },
            
            overrideAnimations: function() {
                const animations = document.getAnimations();
                animations.forEach(animation => {
                    if (!animation._originalTiming) {
                        animation._originalTiming = {
                            duration: animation.effect.getTiming().duration,
                            delay: animation.effect.getTiming().delay
                        };
                        
                        const newDuration = (this.totalFrames * 1000/this.frameRate);
                        animation.effect.updateTiming({ duration: newDuration });
                    }
                });
            },
            
            setTotalFrames: function(frames) {
                this.totalFrames = frames;
                const newDuration = (frames * 1000/this.frameRate);
                
                document.getAnimations().forEach(animation => {
                    animation.effect.updateTiming({ duration: newDuration });
                });
            },
            
            seekToFrame: function(frame) {
                const timestamp = (frame * 1000/this.frameRate);
                document.getAnimations().forEach(animation => {
                    animation.currentTime = timestamp;
                });
            },
            
            play: function() {
                this.isPaused = false;
                document.getAnimations().forEach(animation => {
                    animation.play();
                });
            },
            
            pause: function() {
                this.isPaused = true;
                document.getAnimations().forEach(animation => {
                    animation.pause();
                });
            }
        };
        
        window.__animationController.initialize();
    )";
};
