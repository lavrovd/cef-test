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
    void setFrameRate(CefRefPtr<CefBrowser> browser, int fps);
    void seekToFrame(CefRefPtr<CefBrowser> browser, int frame);
    void play(CefRefPtr<CefBrowser> browser);
    void pause(CefRefPtr<CefBrowser> browser);
    
private:
    const char* controlScript = R"(
        window.__animationController = {
            frameRate: 30,
            totalFrames: 100,
            currentFrame: 0,
            isPaused: false,
            originalDurations: new Map(),
            
            initialize: function() {
                this.overrideAnimations();
                document.addEventListener('animationstart', () => this.overrideAnimations());
                
                // Add frame update callback
                requestAnimationFrame(() => this.updateFrame());
            },
            
            updateFrame: function() {
                if (!this.isPaused) {
                    const animations = document.getAnimations();
                    if (animations.length > 0) {
                        const mainAnim = animations[0];
                        const progress = mainAnim.currentTime / mainAnim.effect.getTiming().duration;
                        this.currentFrame = Math.round(progress * this.totalFrames);
                        
                        // Dispatch frame update event
                        window.dispatchEvent(new CustomEvent('frameUpdate', {
                            detail: {
                                currentFrame: this.currentFrame,
                                totalFrames: this.totalFrames,
                                frameRate: this.frameRate
                            }
                        }));
                    }
                }
                requestAnimationFrame(() => this.updateFrame());
            },
            
            overrideAnimations: function() {
                const animations = document.getAnimations();
                animations.forEach(animation => {
                    if (!this.originalDurations.has(animation)) {
                        this.originalDurations.set(animation, {
                            duration: animation.effect.getTiming().duration,
                            delay: animation.effect.getTiming().delay
                        });
                        
                        const newDuration = (this.totalFrames * 1000/this.frameRate);
                        animation.effect.updateTiming({ duration: newDuration });
                    }
                });
            },
            
            setFrameRate: function(fps) {
                this.frameRate = fps;
                const newDuration = (this.totalFrames * 1000/fps);
                
                document.getAnimations().forEach(animation => {
                    animation.effect.updateTiming({ duration: newDuration });
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
                this.currentFrame = frame;
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
