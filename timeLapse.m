classdef  timeLapse < handle
    % Time Lapse Writer
    % Matt Ireland 2020
    
    % This largely wraps the matlab VideoWriter class and scripts dir
    % search, looping etc
    
    % Pass an output filename and framerate to the constructor to produce
    % a lossless avi video
    
    properties
        name
        imageNames
        frate
        
        cropped
        currentWindow
        
        outputVideo
        
    end
    
    % Class Constructor
    methods
        function obj = timeLapse(outputFilename,frate)
            
            obj.name = outputFilename;
            obj.frate = frate;
            
            % Grab current directory contents
            iNames = dir(fullfile(pwd,'*.jpg'));
            obj.imageNames = {iNames.name}';
            
            % Write out options
            y = {
                ''
                'Time Lapse Object Created'
                'Options:'
                ' '
                '     obj.prepVideo(obj,varargin) '
                '       % make the video file at framerate=varargin, or if absent: at framerate=obj.frate'
                '     obj.compileVideo(framerate) '
                '       % compiles the video in pwd'
                '     obj.cropImage(obj,index,window)'
                '       % crops the indexed image by window=[xmin ymin dx dy] (4th quadrant coordsys)'
                '     obj.matchCrop(obj,index,rFlag)'
                '       % matches the previously cropped window to indexed image, renderFlag=[0,1] '
                };
            fprintf('%s\n',y{:});
        end
    end
    
    % Future capabilities
    methods
        
        function obj = prepVideo(obj,varargin)
            % Accepts:
            %       -obj of the class
            %       -framerate (option)
            % Sets obj.frate if included
            % Builds the outputVideo
            
            if ~isempty(nargin); obj.frate = varargin; end
            
            % Initialize output file
            obj.outputVideo = VideoWriter(fullfile(pwd,obj.name));
            obj.outputVideo.FrameRate = obj.frate;
        end
        
        function obj = compileVideo(obj)
            % Accepts:
            %       -obj of the class
            % Opens, compiles, and closes the 
            % current outputVideo to file
            
            % open the prepped file
            open(obj.outputVideo)
            
            % Add files sequentially
            for ii = 1:length(obj.imageNames)
                disp(['Frame ' num2str(ii) ' of ' num2str(length(obj.imageNames))]);
                img = imread(fullfile(pwd,obj.imageNames{ii}));
                writeVideo(obj.outputVideo,img)
            end
            
            % close the file
            close(obj.outputVideo);
        end
        
        function obj = cropImage(obj,index,window)
            % Accepts:
            %       -obj of the class
            %       -image index
            %       -cropping window
            % Sets the current window property
            % Populates obj.cropped
            
            obj.currentWindow = window;
            img = imread(char(obj.imageNames(index)));
            
            obj.cropped = imcrop(img,window);
            
        end
        
        function obj = matchCrop(obj,index,renderFlag)
             % Accepts:
            %       -obj of the class
            %       -image index
            %       -render flag
            % Matches the current crop to indexed image
            % Can output xcorrelate, superimposed, etc
            
            % assign variables
            crop = obj.cropped;
            fullFrame = imread(char(obj.imageNames(index)));
            % normalized cross-correllation
            c = normxcorr2(crop(:,:,1),fullFrame(:,:,1));
            % offset found by correlation
            [~, imax] = max(abs(c(:)));
            [ypeak, xpeak] = ind2sub(size(c),imax(1));
            offset = [(xpeak-size(crop,2)) (ypeak-size(crop,1))];
            xoffset = offset(1); yoffset = offset(2);
            xbegin = round(xoffset+1);
            xend   = round(xoffset+ size(crop,2));
            ybegin = round(yoffset+1);
            yend   = round(yoffset+size(crop,1));
            % extract region from fullFrame and compare to crop
            extracted_crop = fullFrame(ybegin:yend,xbegin:xend,:);
            if isequal(crop,extracted_crop)
                disp('The crop is from the same image')
            end
            % place the crop in an empty image sized equal to fullFrame
            recovered_crop = uint8(zeros(size(fullFrame)));
            recovered_crop(ybegin:yend,xbegin:xend,:) = crop;
            
            % show crop overlay data
            if renderFlag == 1
                figure();
                contourf(c); 
                pbaspect([size(fullFrame,[1 2])'; 1]')
                
                figure(); 
                imshow(recovered_crop);
                
                figure(); 
                imshowpair(fullFrame(:,:,1),recovered_crop,'blend');
            end
        end
    end
end

