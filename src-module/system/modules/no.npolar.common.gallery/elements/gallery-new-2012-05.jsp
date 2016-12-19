<%-- 
    Document   : gallery-new-2012-05
    Created on : May 8, 2012, 2:05:57 PM
    Author     : flakstad
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
                 org.opencms.loader.CmsImageScaler" session="true"
%><%
// JSP action element + some useful variables
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String requestFolderUri     = cms.getRequestContext().getFolderUri();
Locale locale               = cms.getRequestContext().getLocale();
String loc                  = locale.toString();
int galleryIndex            = 0;

final String SHARE_LINKS    = "../../no.npolar.common.pageelements/elements/share-addthis-" + loc + ".txt";

// Make template includable as extension in Ivorypage (check if resource parameter is set)
String resourceUri          = request.getParameter("resourceUri") != null ? request.getParameter("resourceUri") : requestFileUri;
boolean isIncluded          = false;
if (request.getParameter("resourceUri") != null) {
    resourceUri = request.getParameter("resourceUri");
    isIncluded = true;
}

final boolean EDITABLE      = false;

// Scaler types. See doc for "cms:img" tag http://www.bng-galiza.org/opencms/opencms/alkacon-documentation/documentation_taglib/docu_tag_img.html for more info
final int SCALE_TYPE_DEFAULT= 0; // keep aspect ratio - fill with background color to fit target size
final int SCALE_TYPE_THUMB  = 1; // keep aspect ratio - never enlarge, and fill with background color to fit target size
final int SCALE_TYPE_CUT    = 2; // keep aspect ratio - cut what doesn't fit inside target size
final int SCALE_TYPE_FIT    = 3; // keep aspect ratio - adjust target size if needed
final int SCALE_TYPE_EXACT  = 4; // ignore aspect ratio - scale to the given size

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
boolean downloadLinks       = false;
String downloadFolderUri    = null;

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
    downloadLinks       = Boolean.valueOf(cms.contentshow(galleryConfig, "DownloadLinks")).booleanValue();
    downloadFolderUri   = cms.contentshow(galleryConfig, "DownloadFolder");
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


if (CmsAgent.elementExists(text))
    out.println("<div class=\"ingress\">" + text + "</div><!-- .intro -->");

if (i.hasNext()) {
    try {
        out.println("<ul class=\"gallery\">");
        reScaler = new CmsImageProcessor(CmsImageScaler.SCALE_PARAM_WIDTH + ":" + thumbnailSize + "," + 
                                            CmsImageScaler.SCALE_PARAM_HEIGHT + ":" + thumbnailSize + "," +
                                            CmsImageScaler.SCALE_PARAM_TYPE + ":" + SCALE_TYPE_CUT + "," +
                                            CmsImageScaler.SCALE_PARAM_QUALITY + ":" + thumbnailQuality);
        
        //out.println("<p>rescaling to w:" + reScaler.getWidth() + ",h:"+reScaler.getHeight() + "</p>");
        
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
            /*
            imgPro = new CmsImageProcessor(cms.getCmsObject(), file);
            
            
            // Landscape
            if (imgPro.getWidth() >= imgPro.getHeight()) {
                reScaler = 
                        new CmsImageProcessor(CmsImageScaler.SCALE_PARAM_WIDTH + ":" + thumbnailSize + "," + 
                                              CmsImageScaler.SCALE_PARAM_HEIGHT + ":" + cms.calculateNewImageHeight(thumbnailSize, imgPro.getWidth(), imgPro.getHeight()) + "," +
                                              CmsImageScaler.SCALE_PARAM_TYPE + ":" + SCALE_TYPE_EXACT + "," +
                                              CmsImageScaler.SCALE_PARAM_QUALITY + ":" + thumbnailQuality);
            }
            // Portrait 
            else {
                reScaler = 
                        new CmsImageProcessor(CmsImageScaler.SCALE_PARAM_HEIGHT + ":" + thumbnailSize + "," + 
                                              CmsImageScaler.SCALE_PARAM_WIDTH + ":" + cms.calculateNewImageHeight(thumbnailSize, imgPro.getHeight(), imgPro.getWidth()) + "," +
                                              CmsImageScaler.SCALE_PARAM_TYPE + ":" + SCALE_TYPE_EXACT + "," +
                                              CmsImageScaler.SCALE_PARAM_QUALITY + ":" + thumbnailQuality);
            }
            */
            //out.println("<!-- rescaling to w:" + reScaler.getWidth() + ",h:" + reScaler.getHeight() + " -->");
            //String imageTag = cms.img(cms.getCmsObject().getSitePath(file), imgPro.getCropScaler(reScaler), null); // This one doesn't work
            String imageTag = cms.img(cms.getCmsObject().getSitePath(file), reScaler, null);
            //out.println("<!-- cms.img() returned " + imageTag + " -->");
            String imageSrc = (String)CmsAgent.getTagAttributesAsMap(imageTag).get("src");
            imageTag = "<img src=\"" + imageSrc + "\" alt=\"" + fileTitle + "\" />";
            
            out.println("<li class=\"gallerythumb\" id=\"" + fileName +"\">");
            out.println("\t<a href=\"" + cms.link(cms.getCmsObject().getSitePath(file)) + "\""
                                + " class=\"thumbnail highslide\"" 
                                + " onclick=\"return hs.expand(this)\""
                                + ">"
                            + "\n\t\t" + imageTag
                            + "\n\t\t<span class=\"image-overlay\"></span>"
                        + "\n\t</a>"
                        + "\n\t<span class=\"caption highslide-caption\" style=\"display:none;\">" + fileDescr + "</span>");
            /*
            if (fileDescr != null)
                out.println("<span class=\"highslide-caption\">" + fileDescr + "</span>");
            */
            out.println("</li><!-- gallerythumb -->");
        } // END while
        out.println("</ul><!-- gallery -->");
    }
    catch (java.lang.OutOfMemoryError e) {
        throw new ServletException("Out of memory while processing images."); 
    }
}

//HTML LAYOUT 
if (!isIncluded)
    out.println(cms.getContent(SHARE_LINKS));
    cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[1], true);
%>
