function params = export_psd_dreem_plots(varargin)
    if(nargin == 0)        
        x = DMExportDreemPlots([mfilename('fullpath'),'.plist']);
        params = x.params;
    else
        x = DMExportDreemPlots(varargin{:});
        params = isa(x,'DMExportDreemPlots') && x.status.finished;
    end
end