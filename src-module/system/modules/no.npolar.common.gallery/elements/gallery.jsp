<%-- 
    Document   : gallery-NEW
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
                 org.opencms.loader.CmsImageScaler" session="true"
%><%
// JSP action element + some useful variables
CmsAgent cms                = new CmsAgent(pageContext, request, response);
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();
int galleryIndex            = 0;

final String SHARE_LINKS            = "../../no.npolar.site.npweb/elements/share-addthis-" + loc + ".txt";

// Make template includable as extension in Ivorypage (check if resource parameter is set)
String resourceUri          = request.getParameter("resourceUri") != null ? request.getParameter("resourceUri") : requestFileUri;
boolean isIncluded          = false;
if (request.getParameter("resourceUri") != null) {
    resourceUri = request.getParameter("resourceUri");
    isIncluded = true;
}

final boolean EDITABLE      = false;
final int SCALER_TYPE       = 3; // downscale only, keep proportions 
final String HEADING_TYPE   = isIncluded ? "h2" : "h1";
final int SUM_THUMB_BORDERS = 2; // sum width of thumbnail border: 1px border to define the thumbnail's quadratic box, 1px border around the image

// Variables for reading XML contents
String title                = null;
String teaser               = null;
String text                 = null;
String galleryFolderUri     = null;
String coverImage           = null;
int thumbnailSize           = -1;
int thumbnailQuality        = -1;

// Read XML contents into variables
I_CmsXmlContentContainer galleryConfig = cms.contentload("singleFile", resourceUri, EDITABLE);
while (galleryConfig.hasMoreContent()) {
    title               = cms.contentshow(galleryConfig, "Title");
    teaser              = cms.contentshow(galleryConfig, "Teaser");
    text                = cms.contentshow(galleryConfig, "Text");
    galleryFolderUri    = cms.contentshow(galleryConfig, "ImageFolder");
    coverImage          = cms.contentshow(galleryConfig, "CoverImage");
    thumbnailSize       = Integer.parseInt(cms.contentshow(galleryConfig, "ThumbnailSize"));
    thumbnailQuality    = cms.contentshow(galleryConfig, "ThumbnailQuality").equals("high") ? 100 : 80;
}

CmsResource file            = null; // The current image
String fileName             = null; // Image name
String fileTitle            = null; // Image title
String fileDescr            = null; // Image description

CmsResourceFilter imgFilter = CmsResourceFilter.DEFAULT.requireType(CmsResourceTypeImage.getStaticTypeId());
//List fullSizeImages         = cms.getCmsObject().getFilesInFolder(galleryFolderUri, imgFilter);
List fullSizeImages         = cms.getCmsObject().readResources(galleryFolderUri, imgFilter, true);
Iterator i                  = fullSizeImages.iterator();

CmsImageProcessor imgPro    = null;
CmsImageProcessor reScaler  = null;

String LABEL_TITLE          = CmsAgent.elementExists(title) ? title : cms.getCmsObject().readPropertyObject(galleryFolderUri, "Title", false).getValue("Gallery");
String LABEL_INFO           = cms.labelUnicode("info.gallery.viewnativesize");
String LABEL_STAT           = cms.labelUnicode("label.gallery.numberofimages") + ": " + fullSizeImages.size();

//HTML LAYOUT 
if (!isIncluded)
    cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[0], true);

out.println("<" + HEADING_TYPE + ">" + LABEL_TITLE + "</" + HEADING_TYPE + ">");
//out.println("<div class=\"page\">");
//out.println("<div align=\"center\">");

//out.println("<h3>" + LABEL_INFO + "</h3>");
//out.println("<h4>" + LABEL_STAT + "</h4>");

if (CmsAgent.elementExists(text))
    out.println("<div class=\"ingress\">" + text + "</div><!-- .intro -->");

if (i.hasNext()) {
    try {
        out.println("<div class=\"gallery\">");
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
            
            out.println("<div class=\"gallerythumb\" style=\"" +
                                            "width:" + (thumbnailSize+SUM_THUMB_BORDERS) + "px;" +
                                            " height:" + (thumbnailSize+SUM_THUMB_BORDERS) + "px;" +
                                            " line-height:" + (thumbnailSize+SUM_THUMB_BORDERS) + "px;" +
                                            "\">");
            out.println("\t<div class=\"thumbnail-wrapper\">");
            out.println("\t\t<a href=\"" + cms.link(cms.getCmsObject().getSitePath(file)) + "\"" + /*"title=\"" + fileTitle + "\"" +*/
                                " style=\"" +
                                            "width:" + (thumbnailSize+SUM_THUMB_BORDERS) + "px;" +
                                            " height:" + (thumbnailSize+SUM_THUMB_BORDERS) + "px;" +
                                            " line-height:" + (thumbnailSize+SUM_THUMB_BORDERS) + "px;" +
                                            "\"" +
                                " class=\"thumbnail highslide\" onclick=\"return hs.expand(this)\">" +
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
//out.println("</div><!-- div align=center -->");
//out.println("</div><!-- page -->");

//HTML LAYOUT 
if (!isIncluded)
    out.println(cms.getContent(SHARE_LINKS));
    cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[1], true);
%>
