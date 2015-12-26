function [trueEyePos, tempDist, rawEyePos] = ...
                        getEyePos(x0, y0, eye_used, debugMode, expWin)
% Specify (x0, y0) as the center of the screen, which eye is being used
% (0: left, 1:right), if in debug mode, and experimental window.
%
% Returns trueEyePos (eye position minus center of the screen (x0, y0))
%         tempDist (euclidean distance from center of the screen)
%         rawEyePos (position of the eyes as returned by the Eyelink)
%
% Adapted from Alireza Soltani's lab code
    if debugMode % use mouse position, rather than eye position
        [eyePos.gx(1), eyePos.gy(1)] = GetMouse(expWin);
    else
        eyePos = Eyelink('NewestFloatSample');
    end
    xPos = eyePos.gx(eye_used+1)-x0;
    yPos = eyePos.gy(eye_used+1)-y0;
    rawEyePos = [eyePos.gx(eye_used+1), eyePos.gy(eye_used+1)];
    trueEyePos=[xPos, yPos];
    tempDist = sqrt(xPos^2+yPos^2);
end

