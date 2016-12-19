<%-- 
    Document   : gallery-list.jsp (NEW)
    Created on : 26.okt.2009, 17:03:05
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%><%@ page import="no.npolar.util.CmsAgent,
                 no.npolar.util.CmsImageProcessor,
                 java.util.List,
                 java.util.Locale,
                 java.util.Iterator,
                 org.opencms.file.CmsResource,
                 org.opencms.file.CmsResourceFilter,
                 org.opencms.file.types.CmsResourceTypeImage, 
                 org.opencms.jsp.I_CmsXmlContentContainer, 
                 org.opencms.main.OpenCms,
                 org.opencms.loader.CmsImageScaler" session="true"
%><%
// JSP action element + some commonly used stuff
CmsAgent cms                = new CmsAgent(pageContext, request, response);
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();


// Constants
final String LIST_FOLDER    = cms.getTemplateSearchFolder() != null ? cms.getTemplateSearchFolder() : requestFolderUri;
final int TYPE_ID           = OpenCms.getResourceManager().getResourceType("gallery").getTypeId();
final boolean EDITABLE      = false;
final int SCALER_TYPE       = 3; // downscale only, keep proportions
final String HEADING_TYPE   = "h3";
final String QUALITY_HIGH   = "high";

final boolean LIST_SUBTREE  = Boolean.valueOf(cms.property("template-search-subtree", requestFileUri, "false")).booleanValue();
final String COLLECTOR      = "allIn" + (LIST_SUBTREE ? "SubTree" : "Folder") + "NavPos";

// Variables for reading XML contents
String title                = null;
String teaser               = null;
String coverImage           = null;
String uri                  = null;

// Convenience variables
String link                 = null;
int thumbnailSize           = -1;
int thumbnailQuality        = -1;

// CmsImageProcessors, used for image scaling
CmsImageProcessor imgPro    = null;
CmsImageProcessor reScaler  = null;

// The "cover" image for the gallery and its alt text
CmsResource file    = null;
String fileTitle    = null;

// Load all galleries in the specified folder
I_CmsXmlContentContainer galleries = cms.contentload(COLLECTOR, LIST_FOLDER.concat("|").concat(Integer.toString(TYPE_ID)), EDITABLE);

// Start the gallery list wrapper
out.println("<div class=\"galleries\">");

// Loop through all galleries
while (galleries.hasMoreContent()) {
    title               = cms.contentshow(galleries, "Title");
    teaser              = cms.contentshow(galleries, "Teaser");
    coverImage          = cms.contentshow(galleries, "CoverImage");
    thumbnailSize       = Integer.parseInt(cms.contentshow(galleries, "ThumbnailSize"));
    thumbnailQuality    = cms.contentshow(galleries, "ThumbnailQuality").equals(QUALITY_HIGH) ? 100 : 80;
    uri                 = cms.contentshow(galleries, "%(opencms.filename)");

    file                = cms.getCmsObject().readResource(coverImage);
    fileTitle           = cms.getCmsObject().readPropertyObject(file, "Title", false).getValue("");
    String imageTag     = null;

    if (CmsAgent.elementExists(coverImage)) {
        // Get a CmsImageProcessor for the current "cover" image
        imgPro              = new CmsImageProcessor(cms.getCmsObject(), file);
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
        // Get a correctly dimensioned version of the "cover" image
        imageTag = cms.img(cms.getCmsObject().getSitePath(file), imgPro.getDownScaler(reScaler), null);
        // Insert alt text
        imageTag = imageTag.replace("/>", " alt=\"" + fileTitle + "\" />");
    }
    // Make the "cover" image a link to the gallery
    link = "<a href=\"" + cms.link(uri) + "\">";
    
    
    // The HTML output for the current gallery
    out.println("<div class=\"gallery\">");
    if (imageTag != null)
        out.println("\t" + link + imageTag + "</a>");
    out.println("<" + HEADING_TYPE + ">" + link + title + "</a></" + HEADING_TYPE + ">");
    if (CmsAgent.elementExists(teaser))
        out.println("<p>" + teaser + "</p>");
    out.println("</div><!-- gallery -->");
}

// End the gallery list wrapper
out.println("</div><!-- .galleries -->");
%>
