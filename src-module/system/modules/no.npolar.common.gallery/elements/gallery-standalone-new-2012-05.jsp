<%-- 
    Document   : gallery-standalone
    Created on : 08.sep.2011
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.CmsAgent,
                 no.npolar.util.CmsImageProcessor,
                 java.util.List,
                 java.util.Locale,
                 java.util.Iterator,
                 org.apache.commons.lang.StringUtils,
                 org.opencms.file.CmsObject,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.types.CmsResourceTypeImage, 
                 org.opencms.jsp.I_CmsXmlContentContainer, 
                 org.opencms.loader.CmsImageScaler,
                 org.opencms.main.OpenCms" session="true"
%><%
// JSP action element + some useful variables
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();
int galleryIndex            = 0;

// Get the path to the gallery file
String resourceUri          = (String)request.getAttribute("resourceUri");
// If no path was set, abort
if (resourceUri == null) {
    throw new NullPointerException("Embedding image gallery failed: Path to image gallery was empty.");
}
try {
    galleryIndex = ((Integer)request.getAttribute("galleryIndex")).intValue();
} catch (Exception e) {
    throw new NullPointerException("Embedding image gallery failed: Unable to determine the gallery index.");
}
// A value was found for the path, check that it points to a valid resource
CmsResource imageGalleryResource = cmso.readResource(resourceUri);
if (imageGalleryResource.getTypeId() != OpenCms.getResourceManager().getResourceType("gallery").getTypeId()) {
    throw new IllegalArgumentException("Embedding image gallery failed: The path supplied did not point to a resource of type 'gallery'.");
}

final boolean EDITABLE      = false;

// Scaler types. See doc for "cms:img" tag http://www.bng-galiza.org/opencms/opencms/alkacon-documentation/documentation_taglib/docu_tag_img.html for more info
final int SCALE_TYPE_DEFAULT= 0; // keep aspect ratio - fill with background color to fit target size
final int SCALE_TYPE_THUMB  = 1; // keep aspect ratio - never enlarge, and fill with background color to fit target size
final int SCALE_TYPE_CUT    = 2; // keep aspect ratio - cut what doesn't fit inside target size
final int SCALE_TYPE_FIT    = 3; // keep aspect ratio - adjust target size if needed
final int SCALE_TYPE_EXACT  = 4; // ignore aspect ratio - scale to the given size

final int SCALER_TYPE       = 3; // downscale only, keep proportions 
final String DEFAULT_HEADING_TYPE   = "h2";
final int SUM_THUMB_BORDERS = 2; // sum width of thumbnail border: 1px border to define the thumbnail's quadratic box, 1px border around the image

// Variables for reading XML contents
String title                = null;
String teaser               = null;
String text                 = null;
String galleryFolderUri     = null;
String coverImage           = null;
int thumbnailSize           = -1;
int thumbnailQuality        = -1;
boolean thumbnailCaption    = false;
boolean downloadLinks       = false;
String downloadFolderUri    = null;
String headingType          = DEFAULT_HEADING_TYPE;

// Check for thumbnail size overridde
try {
    thumbnailSize = ((Integer)request.getAttribute("thumbnailSize")).intValue();
} catch (Exception e) {
    thumbnailSize = -1; // Keep default value
}
// Check for heading type override
try {
    headingType = ((String)request.getAttribute("headingType"));
} catch (Exception e) {
    headingType = DEFAULT_HEADING_TYPE; // Keep default value
}

// Read XML contents into variables
I_CmsXmlContentContainer galleryConfig = cms.contentload("singleFile", resourceUri, EDITABLE);
while (galleryConfig.hasMoreContent()) {
    title               = cms.contentshow(galleryConfig, "Title");
    teaser              = cms.contentshow(galleryConfig, "Teaser");
    text                = cms.contentshow(galleryConfig, "Text");
    galleryFolderUri    = cms.contentshow(galleryConfig, "ImageFolder");
    coverImage          = cms.contentshow(galleryConfig, "CoverImage");
    if (thumbnailSize == -1) // Allow the script that includes this gallery to override the thumbnail size specified in the gallery file
        thumbnailSize       = Integer.parseInt(cms.contentshow(galleryConfig, "ThumbnailSize"));
    thumbnailQuality    = cms.contentshow(galleryConfig, "ThumbnailQuality").equals("high") ? 100 : 80;
    thumbnailCaption    = Boolean.valueOf(cms.contentshow(galleryConfig, "ThumbnailCaption")).booleanValue();
    downloadLinks       = Boolean.valueOf(cms.contentshow(galleryConfig, "DownloadLinks")).booleanValue();
    downloadFolderUri   = cms.contentshow(galleryConfig, "DownloadFolder");
}

CmsResource file            = null; // The current image
String fileName             = null; // Image name
String fileTitle            = null; // Image title
String fileDescr            = null; // Image description

CmsResourceFilter imgFilter = CmsResourceFilter.requireType(CmsResourceTypeImage.getStaticTypeId());
//List fullSizeImages         = cms.getCmsObject().getFilesInFolder(galleryFolderUri, imgFilter);
List fullSizeImages         = cms.getCmsObject().readResources(galleryFolderUri, imgFilter, true);
Iterator i                  = fullSizeImages.iterator();

CmsImageProcessor imgPro    = null;
CmsImageProcessor reScaler  = null;

String LABEL_TITLE          = CmsAgent.elementExists(title) ? title : cms.getCmsObject().readPropertyObject(galleryFolderUri, "Title", false).getValue("Gallery");
String LABEL_INFO           = cms.labelUnicode("info.gallery.viewnativesize");
String LABEL_STAT           = cms.labelUnicode("label.gallery.numberofimages") + ": " + fullSizeImages.size();


out.println("<" + headingType + ">" + LABEL_TITLE + "</" + headingType + ">");
//out.println("<div align=\"center\">");

//out.println("<h3>" + LABEL_INFO + "</h3>");
//out.println("<h4>" + LABEL_STAT + "</h4>");

if (CmsAgent.elementExists(text))
    out.println(text);

if (i.hasNext()) {
    try {
        out.println("<ul class=\"paragraph gallery\">");
        reScaler = new CmsImageProcessor(CmsImageScaler.SCALE_PARAM_WIDTH + ":" + thumbnailSize + "," + 
                                            CmsImageScaler.SCALE_PARAM_HEIGHT + ":" + thumbnailSize + "," +
                                            CmsImageScaler.SCALE_PARAM_TYPE + ":" + SCALE_TYPE_CUT + "," +
                                            CmsImageScaler.SCALE_PARAM_QUALITY + ":" + thumbnailQuality);


        /*if (downloadLinks) {
            out.println("<!-- download links will be included -->");
            if (CmsAgent.elementExists(downloadFolderUri)) {
                out.println("<!-- looking for extra downloads in '"+ downloadFolderUri +"' -->");
            }
        }*/
        while (i.hasNext()) {
            file        = (CmsResource)i.next();
            fileName    = file.getName();
            fileTitle   = cms.getCmsObject().readPropertyObject(file, "Title", false).getValue();
            //fileDescr   = cms.getCmsObject().readPropertyObject(galleryFolderUri.concat(fileName), "Description", false).getValue();
            fileDescr   = cms.getCmsObject().readPropertyObject(cms.getRequestContext().removeSiteRoot(file.getRootPath()), "Description", false).getValue("");
            
            // Show download links?
            if (downloadLinks) {
                String fileBaseName = StringUtils.substringBeforeLast(fileName, ".");
                String fileExtension = StringUtils.substringAfterLast(fileName, ".").toUpperCase();
                
                String dlStr = "<a class=\"galleryimage-dl cta alt\" href=\"" + cms.getCmsObject().getSitePath(file) + "\" target=\"_blank\">" 
                                        + "<i class=\"icon-download-alt\"></i> " + fileExtension + "</a>"; // the font icon used here is from fontello
                
                if (CmsAgent.elementExists(downloadFolderUri)) {
                    List allDownloadFiles = cmso.readResources(downloadFolderUri, CmsResourceFilter.DEFAULT_FILES, true);
                    Iterator iAllDownloadFiles = allDownloadFiles.iterator();
                    while (iAllDownloadFiles.hasNext()) {
                        CmsResource downloadFile = (CmsResource)iAllDownloadFiles.next();
                        String downloadFileBaseName = StringUtils.substringBeforeLast(downloadFile.getName(), ".");
                        if (downloadFileBaseName.equalsIgnoreCase(fileBaseName)) {
                            String downloadFileExtension = StringUtils.substringAfterLast(downloadFile.getName(), ".").toUpperCase();
                            dlStr += " <span class=\"galleryimage-dl-separator\">|</span> "
                                    + "<a class=\"galleryimage-dl cta alt\" href=\"" + cms.link(cmso.getSitePath(downloadFile)) + "\" target=\"_blank\">" 
                                            + "<i class=\"icon-download-alt\"></i> " + downloadFileExtension + "</a>"; // the font icon used here is from fontello
                        }
                    }
                }
                
                fileDescr += (fileDescr.isEmpty() ? "" : "<br />") + dlStr;
            }
            
            String imageTag = cms.img(cms.getCmsObject().getSitePath(file), reScaler, null);
            String imageSrc = (String)CmsAgent.getTagAttributesAsMap(imageTag).get("src");
            imageTag = "<img src=\"" + imageSrc + "\" alt=\"" + fileTitle + "\" />";
            
            String tnCapStyle = "position:absolute; display:block; left:1px; bottom:1em; width:100%; "
                                    + "background:#000; background:rgba(0,0,0,0.75); color:#fff; font-size:0.8rem; text-align:center;";
            
            out.println("<li class=\"gallerythumb\" style=\"position:relative;\">");
            out.println("\t<a href=\"" + cms.link(cms.getCmsObject().getSitePath(file)) + "\""
                                + " class=\"thumbnail highslide\"" 
                                + " onclick=\"return hs.expand(this, galleryOptions_" + galleryIndex + ")\""
                                + ">"
                            + "\n\t\t" + imageTag
                            + "\n\t\t<span class=\"image-overlay\"></span>"
                        + "\n\t</a>"
                        + (thumbnailCaption ? ("\n\t<span class=\"caption\" style=\"" + tnCapStyle + "\">" + fileTitle + "</span>") : "")
                        + "\n\t<span class=\"caption highslide-caption\" style=\"display:none;\">" + fileDescr + "</span>");
            
            out.println("</li><!-- gallerythumb -->");
        } // END while
        out.println("</ul><!-- gallery -->");
        
        %>
        <script type="text/javascript">
            hs.addSlideshow({
                slideshowGroup: 'gallery<%= galleryIndex %>',
                interval: 5000,
                repeat: true,
                useControls: true,
                fixedControls: true,
                //fixedControls: false,
                //fixedControls: 'fit',
                overlayOptions: { // Gallery controls. See http://highslide.com/ref/hs.registerOverlay
                    //opacity: .6,
                    opacity: .999,
                    //position: 'top center',
                    position: 'above', 
                    //hideOnMouseOut: true
                    hideOnMouseOut: false
                    //,className: 'text-controls'
                    //,relativeTo: 'viewport'
                    ,relativeTo: 'expander'
                    //,offsetX: '1'
                    //,offsetY: '-10'
                }
                ,thumbstrip: {
                    //position: 'leftpanel'
                    position: 'top center'
                    ,mode: 'horizontal'
                    ,relativeTo: 'viewport'
                    //,offsetY: -60
                }
            });
            var galleryOptions_<%= galleryIndex %> = {
                slideshowGroup: 'gallery<%= galleryIndex %>',
                align: 'center',
                marginLeft: 600,
                //marginBottom: 120,
                //marginTop: 30,
                transitions: ['expand', 'crossfade'],
                //transitions: ['fade'],
                //outlineType: 'glossy-dark',
                wrapperClassName: 'dark',
                //outlineType: 'rounded-white',
                outlineType: null,
                fadeInOut: true,
                dimmingOpacity: 0.9,
                dimmingDuration: 450
            }
        </script>
<%
        
    }
    catch (java.lang.OutOfMemoryError e) { 
        throw new ServletException("Out of memory while processing images."); 
    }
}
%>