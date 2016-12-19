<%-- 
    Document   : gallery-standalone
    Created on : 08.sep.2011
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.CmsAgent,
                 no.npolar.util.CmsImageProcessor,
                 java.util.List,
                 java.util.Locale,
                 java.util.Iterator,
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
    if (thumbnailSize == -1) // Allow overriding of the thumbnail size
        thumbnailSize       = Integer.parseInt(cms.contentshow(galleryConfig, "ThumbnailSize"));
    thumbnailQuality    = cms.contentshow(galleryConfig, "ThumbnailQuality").equals("high") ? 100 : 80;
}

CmsResource file            = null; // The current image
String fileName             = null; // Image name
String fileTitle            = null; // Image title
String fileDescr            = null; // Image description

CmsResourceFilter imgFilter = CmsResourceFilter.requireType(CmsResourceTypeImage.getStaticTypeId());
List fullSizeImages         = cms.getCmsObject().getFilesInFolder(galleryFolderUri, imgFilter);
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
        out.println("<div class=\"paragraph gallery\">");
%>
        <script type="text/javascript">
            hs.addSlideshow({
                slideshowGroup: 'gallery<%= galleryIndex %>',
                interval: 5000,
                repeat: true,
                useControls: true,
                fixedControls: true,
                overlayOptions: {
                    opacity: .6,
                    position: 'top center',
                    hideOnMouseOut: true
                }
            });
            var galleryOptions_<%= galleryIndex %> = {
                slideshowGroup: 'gallery<%= galleryIndex %>',
                align: 'center',
                //marginBottom: 50,
                //marginTop: 30,
                transitions: ['expand', 'crossfade'],
                //outlineType: 'glossy-dark',
                //wrapperClassName: 'dark',
                //outlineType: 'rounded-white',
                fadeInOut: true,
                dimmingOpacity: 0.8,
                dimmingDuration: 300
            }
        </script>
<%
        while (i.hasNext()) {
            file        = (CmsResource)i.next();
            fileName    = file.getName();
            fileTitle   = cms.getCmsObject().readPropertyObject(file, "Title", false).getValue();
            fileDescr   = cms.getCmsObject().readPropertyObject(galleryFolderUri.concat(fileName), "Description", false).getValue();
            
            imgPro = new CmsImageProcessor(cms.getCmsObject(), file);
            reScaler = null;
            
            // Landscape
            if (imgPro.getWidth() >= imgPro.getHeight()) {
                reScaler = 
                        new CmsImageProcessor(CmsImageScaler.SCALE_PARAM_WIDTH + ":" + thumbnailSize + "," + 
                                              CmsImageScaler.SCALE_PARAM_HEIGHT + ":" + cms.calculateNewImageHeight(thumbnailSize, imgPro.getWidth(), imgPro.getHeight()) + "," +
                                              CmsImageScaler.SCALE_PARAM_TYPE + ":" + SCALER_TYPE + "," +
                                              CmsImageScaler.SCALE_PARAM_QUALITY + ":" + thumbnailQuality);
            }
            // Portrait 
            else {
                reScaler = 
                        new CmsImageProcessor(CmsImageScaler.SCALE_PARAM_HEIGHT + ":" + thumbnailSize + "," + 
                                              CmsImageScaler.SCALE_PARAM_WIDTH + ":" + cms.calculateNewImageHeight(thumbnailSize, imgPro.getHeight(), imgPro.getWidth()) + "," +
                                              CmsImageScaler.SCALE_PARAM_TYPE + ":" + SCALER_TYPE + "," +
                                              CmsImageScaler.SCALE_PARAM_QUALITY + ":" + thumbnailQuality);
            }
            
            String imageTag = cms.img(cms.getCmsObject().getSitePath(file), imgPro.getDownScaler(reScaler), null);
            imageTag = imageTag.replace("/>", " alt=\"" + fileTitle + "\" />");
            
            out.println("<div class=\"gallerythumb\" style=\"height:auto; width:auto;\">");
            out.println("\t<div class=\"thumbnail\" style=\"width:" + (thumbnailSize+SUM_THUMB_BORDERS) + "px; height:" + (thumbnailSize+SUM_THUMB_BORDERS) + "px;\">");
            out.println("\t\t<a href=\"" + cms.link(cms.getCmsObject().getSitePath(file)) + "\"" + /*"title=\"" + fileTitle + "\"" +*/
                                " style=\"width:" + (thumbnailSize+SUM_THUMB_BORDERS) + "px; height:" + (thumbnailSize+SUM_THUMB_BORDERS) + "px;\"" +
                                " class=\"thumbnail highslide\" onclick=\"return hs.expand(this, galleryOptions_" + galleryIndex + ")\">" +
                            "\n\t\t\t" + imageTag +
                        "\n\t\t</a>");
            if (fileDescr != null)
                out.println("<div class=\"highslide-caption\">" + fileDescr + "</div>");
            out.println("\t</div><!-- thumbnail -->");
            out.println("</div><!-- gallerythumb -->");
        } // END while
        out.println("</div><!-- gallery -->");
    }
    catch (java.lang.OutOfMemoryError e) { 
        throw new ServletException("Out of memory while processing images."); 
    }
}
%>
