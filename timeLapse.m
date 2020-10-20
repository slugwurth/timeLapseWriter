classdef  timeLapse < handle
    % Time Lapse Writer
    % Matt Ireland 2020
    
    % This largely wraps the matlab VideoWriter class and scripts dir
    % search, looping etc
    
    % Pass an output filename and framerate to the constructor to produce
    % a lossless avi video
    
    properties
        name
        frate
        imageNames
        originals
        outputVideo
        
        numImg
        
        cropSet
        cropped
        currentWindow
        
        reference
        xcorr
        xcorrSet
        
        translation
        tranSet
        
        aligned
        alignSet
        
        frame
        frameSet        
    end
    
    % Class Constructor
    methods
        function obj = timeLapse(outputFilename,frate,preloadFlag)
            
            obj.name = outputFilename;
            obj.frate = frate;
            
            % Grab current directory contents
            iNames = dir(fullfile(pwd,'*.jpg'));
            obj.imageNames = {iNames.name}';
            % number of images in directory
            obj.numImg = size(obj.imageNames,1);
            
            if (preloadFlag)
                % initialize
                obj.originals = cell(obj.numImg,1);
                % read all images in pwd
                for ii = 1:obj.numImg
                    disp(['Loading into memory: Frame ' num2str(ii) ' of ' num2str(obj.numImg)]);
                    obj.originals{ii} = imread(char(obj.imageNames(ii)));
                end
            end
            
            % Write out options
            y = {
                '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
                'Time Lapse Object Created'
                'Functions:'
                '     obj.prepVideo(obj,varargin) '
                '                   % make the video file at framerate=varargin, or if absent: at framerate=obj.frate'
                '       obj.compileVideo(framerate) '
                '                   % compiles the video in pwd from "file" "cropped" or "aligned" '
                ''
                '     obj.setCurrentWindow(obj,window)'
                '                   % assigns window=[xmin ymin dx dy] to the obj.currentWindow property'
                '       obj.cropImage(obj,index,window)'
                '                   % crops the indexed image by obj.currentWindow (4th quadrant coordsys)'
                '           obj.cropAll(obj,index,window)'
                '                   % crops all images from file by obj.currentWindow (4th quadrant coordsys)'
                '           obj.matchCrop(obj,index,rFlag)'
                '                   % matches the previously cropped window to indexed image, renderFlag=[0,1]'
                ''
                '     obj.prepAlign(obj,index,mode)'
                '       % assigns the reference indexed image from "file" "cropped" or "aligned"'
                '     obj.alignAll(obj,index,rFlag)'
                '       % matches the previously cropped window to indexed image, renderFlag=[0,1]'
                ''
                };
            fprintf('%s\n',y{:});
        end
    end
    
    % video file interaction
    methods
        function obj = prepVideo(obj,varargin)
            % Accepts:
            %       -obj of the class
            %       -framerate (option)
            % Sets obj.frate if included
            % Builds the outputVideo
            
            % TODO: varargin can pass a full video parameter set not just frate
            
            if nargin>1; obj.frate = varargin{1}; end
            
            % Initialize output file
            obj.outputVideo = VideoWriter(fullfile(pwd,obj.name),'Motion JPEG AVI');
            obj.outputVideo.FrameRate = obj.frate;
            obj.outputVideo.Quality = 50;
        end
        
        function obj = compileVideo(obj,mode)
            % Accepts:
            %       -obj of the class
            % Opens, compiles, and closes the
            % current outputVideo to file
            
            % open the prepped file
            open(obj.outputVideo)
            
            % Add files sequentially
            for ii = 1:length(obj.imageNames)
                disp(['Frame ' num2str(ii) ' of ' num2str(length(obj.imageNames))]);
                if strcmp(mode, 'file')
                    img = imread(fullfile(pwd,obj.imageNames{ii}));
                    writeVideo(obj.outputVideo,img);
                end
                if strcmp(mode, 'memory')
                    img = obj.originals{ii};
                    writeVideo(obj.outputVideo,img);
                end
                if strcmp(mode,'cropped')
                    img = obj.cropSet{ii};
                    writeVideo(obj.outputVideo,img);
                end
                if strcmp(mode,'aligned')
                    img = obj.alignSet{ii};
                    writeVideo(obj.outputVideo,img);
                end
            end
            
            % close the file
            close(obj.outputVideo);
        end
        
    end
    
    % image cropping
    methods
        function obj = setCurrentWindow(obj,window)
            % Assign the current cropping window
            obj.currentWindow = window;
            
        end
        
        function obj = cropImage(obj,index)
            % Accepts:
            %       -obj of the class
            %       -image index
            % Sets the current window property
            % Populates obj.cropped
            
            % TODO: crop any image passed, not just from file
            
            if ~isempty(obj.currentWindow)
                if isempty(obj.originals)
                    img = imread(char(obj.imageNames(index)));
                    obj.cropped = imcrop(img,obj.currentWindow);
                else
                    img = obj.originals{index};
                    obj.cropped = imcrop(img,obj.currentWindow);
                end
            else
                disp('Please set a window: obj.setCurrentWindow([xmin ymin dx dy])');
                return
            end
            
            
        end
        
        function obj = cropAll(obj)
            
            % TODO: crop from any source set, not just from file
            
            if ~isempty(obj.currentWindow)
                for ii = 1:obj.numImg
                    disp(['Frame ' num2str(ii) ' of ' num2str(obj.numImg)]);
                    obj = cropImage(obj,ii);
                    obj.cropSet{ii} = obj.cropped;
                end
            else
                disp('Please set a window: obj.setCurrentWindow([xmin ymin dx dy])');
                return
            end
        end
        
        function obj = matchCrop(obj,index,mode,renderFlag)
            % Accepts:
            %       -obj of the class
            %       -image index
            %       -render flag
            % Matches the current crop to indexed image
            % Can output xcorrelate, superimposed, etc
            
            % assign variables
            crop = obj.cropped;
            switch mode
                case 'file'
                    fullFrame = imread(char(obj.imageNames(index)));
                case 'memory'
                    fullFrame = obj.originals{index};
                case 'cropped'
                    fullFrame = obj.cropSet{index};
                case 'aligned'
                    fullFrame = obj.alignSet{index};
            end
            
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
    
    % image registration and alignment
    methods
        function obj = prepAlign(obj,index,mode)
            % assign the reference image from indexed set according to mode
           
            if strcmp(mode,'file')
            obj.reference = imread(char(obj.imageNames(index)));
            end
            if strcmp(mode,'memory')
            obj.reference = obj.originals{index};
            end
            if strcmp(mode,'cropped')
            obj.reference = obj.cropSet{index};
            end
            if strcmp(mode,'aligned')
            obj.reference = obj.alignSet{index};
            end
        end
        
        function obj = xcorrImage(obj,index,mode)   
            if strcmp(mode, 'file')
                % assign variables
                crop = obj.reference;
                fullFrame = imread(char(obj.imageNames(index)));
                % normalized cross-correllation
                obj.xcorr = normxcorr2(crop(:,:,1),fullFrame(:,:,1));
            end
            if strcmp(mode, 'memory')
                % assign variables
                crop = obj.reference;
                fullFrame = obj.originals{index};
                % normalized cross-correllation
                obj.xcorr = normxcorr2(crop(:,:,1),fullFrame(:,:,1));
            end
            if strcmp(mode,'cropped')
                % assign variables
                crop = obj.reference;
                fullFrame = obj.cropSet{index};
                % normalized cross-correllation
                obj.xcorr = normxcorr2(crop(:,:,1),fullFrame(:,:,1));
            end
            if strcmp(mode,'aligned')
                % assign variables
                crop = obj.reference;
                fullFrame = obj.alignSet{index};
                % normalized cross-correllation
                obj.xcorr = normxcorr2(crop(:,:,1),fullFrame(:,:,1));
            end
        end
        
        function obj = xcorrAll(obj,mode)
            
            if ~isempty(obj.reference)
                for ii = 1:obj.numImg
                    disp(['Frame ' num2str(ii) ' of ' num2str(obj.numImg)]);
                    obj = xcorrImage(obj,ii,mode);
                    obj.xcorrSet{ii} = obj.xcorr;
                    
                    obj = findTranslation(obj);
                    obj.tranSet{ii} = obj.translation;
                end
            else
                disp('Please set a reference image: obj.prepAlign(obj,index,mode)');
                return
            end
            
        end
        
        function obj = findTranslation(obj)
            % translation offset found by correlation
            [~, imax] = max(abs(obj.xcorr(:)));
            [ypeak, xpeak] = ind2sub(size(obj.xcorr),imax(1));
            obj.translation = [(xpeak-size(obj.reference,2)) (ypeak-size(obj.reference,1))];
        end
        
        function obj = alignImage(obj,index,mode)
            
             % load the the unregistered image
            if strcmp(mode,'file')
                unReg = imread(char(obj.imageNames(index)));
            end
            if strcmp(mode,'memory')
                unReg =  obj.originals{index};
            end
            if strcmp(mode,'cropped')
                unReg = obj.cropSet{index};
            end
            if strcmp(mode,'aligned')
                unReg = obj.alignSet{index};
            end
            
            % find the padding values
            padding = obj.tranSet{index};
            xpad = padding(2); ypad = padding(1);
            
            
            if xpad < 0
                xReg = unReg(1:end+xpad,:,:);
                pad = zeros(abs(xpad),size(xReg,2),size(xReg,3));
                xReg = vertcat(xReg,pad);
            else
                if xpad > 0
                    xReg = unReg(xpad:end,:,:);
                    pad = zeros(abs(xpad-1),size(xReg,2),size(xReg,3));
                    xReg = vertcat(pad,xReg);
                else
                    % No movement
                    xReg = unReg;
                end
            end
            
            
            if ypad < 0
                reg = xReg(:,1:end+ypad,:);
                pad = zeros(size(xReg,1),abs(ypad),size(xReg,3));
                reg = horzcat(reg,pad);
            else
                if ypad > 0
                    reg = xReg(:,ypad:end,:);
                    pad = zeros(size(xReg,1),abs(ypad-1),size(xReg,3));
                    reg = horzcat(pad,reg);
                else
                    % No movement
                    reg = xReg;
                end
            end
            
            obj.aligned = reg;
        end
        
        function obj = alignAll(obj,mode)
            
             if ~isempty(obj.tranSet)
                for ii = 1:obj.numImg
                    disp(['Aligning Frame ' num2str(ii) ' of ' num2str(obj.numImg)]);
                    obj = alignImage(obj,ii,mode);
                    obj.alignSet{ii} = obj.aligned;
                end
            else
                disp('Please cross-correlate all images to the reference: obj.xcorrAll(obj,mode)');
                return
            end
        end
    end
    
    % image rendering
    methods
        function obj = renderFrame(obj,index,rFlag)
            % Renders all available data for specified index
            
            % prep shift plot data out
            shift = obj.tranSet{index};
            xShift = shift(1:2:end-1); yShift = shift(2:2:end);
            
            % toggle rendering
            if (rFlag)
                f = figure();
            else
                f = figure('visible','off');
            end
            sgtitle(['Frame ' num2str(index) ' of ' num2str(obj.numImg)])
            
            subplot(3,2,1)
            if ~isempty(obj.originals)
                imshow(obj.originals{index});
                hDim = size(obj.originals{index},2); vDim = size(obj.originals{index},1);
                pbaspect([hDim vDim 1]);
                title('Orignal');
            else
                text(0,0,'no fullframe data');
            end
            
            subplot(3,2,2)
            if ~isempty(obj.cropSet)
                imshow(obj.cropSet{index});
                title('Current Crop');
            end
            
            subplot(3,2,3)
            if ~isempty(obj.xcorrSet)
                imshow(obj.xcorrSet{index});
                hDim = size(obj.reference,2); vDim = size(obj.reference,1);
                pbaspect([hDim vDim 1]);
                title('xCorr2')
            end
            
            subplot(3,2,4)
            if ~isempty(obj.alignSet)
                imshow(obj.alignSet{index});
                title('Aligned');
            end
            
            subplot(3,2,5)
            if ~isempty(shift)
                scatter(xShift,yShift,'filled');
                pbaspect([1 1 1]);
                title('Alignment');
            end
            subplot(3,2,6)
            if ~isempty(obj.reference)
                imshow(obj.reference);
                title('Reference');
            end
            
            % save to frame property
            f = getframe(gcf);
            obj.frame = frame2im(f);
        end
        
        function obj = renderAll(obj)
            
            for ii = 1:obj.numImg
                disp(['Rendering Frame ' num2str(ii) ' of ' num2str(obj.numImg)]);
                renderFrame(obj,ii,0);
                obj.frameSet{ii} = obj.frame;
                clf;
            end
            
        end
        
    end
end

