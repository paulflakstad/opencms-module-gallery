<%-- 
    Document   : gallery template
    Created on : 26.okt.2009, 17:03:05
    Author     : Paul-Inge Flakstad <flakstad at npolar.no>
--%>
<%@page import="org.opencms.file.CmsPropertyDefinition"%>
<%@page import="no.npolar.util.CmsAgent" %>
<%@page import="no.npolar.util.CmsImageProcessor" %>
<%@page import="no.npolar.util.ImageUtil" %>
<%@page import="java.util.List" %>
<%@page import="java.util.Locale" %>
<%@page import="java.util.Iterator" %>
<%@page import="org.apache.commons.lang.StringUtils" %>
<%@page import="org.opencms.file.CmsObject"%>
<%@page import="org.opencms.file.CmsResource" %>
<%@page import="org.opencms.file.CmsResourceFilter" %>
<%@page import="org.opencms.file.types.CmsResourceTypeImage" %>
<%@page import="org.opencms.jsp.I_CmsXmlContentContainer" %>
<%@page import="org.opencms.loader.CmsImageScaler" %>
<%@page session="true" pageEncoding="UTF-8" %>
<%@page trimDirectiveWhitespaces="true" %>
<%
// JSP action element + some useful variables
CmsAgent cms                = new CmsAgent(pageContext, request, response);
CmsObject cmso              = cms.getCmsObject();
String requestFileUri       = cms.getRequestContext().getUri();
String reqAttrResourceUri   = (String)request.getAttribute("resourceUri");

// Use the manually defined URI (pointing to a gallery file, e.g. when including
// a gallery from another page), or fallback to the request URI
String resourceUri          = reqAttrResourceUri != null ? reqAttrResourceUri : requestFileUri;
final boolean IS_INCLUDED   = resourceUri != requestFileUri;

final String DEFAULT_HEADING_TYPE = IS_INCLUDED ? "h2" : "h1";
final int INDEX_FIRST_GALLERY = 1;
final boolean EDITABLE      = false;
final int DEFAULT_THUMB_SIZE= 400;


// Variables for reading XML contents
String title                = null;
String text                 = null;
String galleryFolderUri     = null;
int thumbnailSize           = -1;
int thumbnailQuality        = -1;
boolean thumbnailCaption    = false;
boolean downloadLinks       = false;
String downloadFolderUri    = null;

// Read XML contents into variables
I_CmsXmlContentContainer galleryConfig = cms.contentload("singleFile", resourceUri, EDITABLE);
while (galleryConfig.hasMoreResources()) {
    title               = cms.contentshow(galleryConfig, "Title");
    text                = cms.contentshow(galleryConfig, "Text");
    galleryFolderUri    = cms.contentshow(galleryConfig, "ImageFolder");
    try { thumbnailSize = Integer.parseInt(cms.contentshow(galleryConfig, "ThumbnailSize"));
        if (thumbnailSize <= 0) {
            throw new NumberFormatException("Thumbnail size set to zero or negative in gallery file " + resourceUri + ".");
        }
    } catch (NumberFormatException nfe) {
        thumbnailSize = DEFAULT_THUMB_SIZE;
    }
    thumbnailQuality    = cms.contentshow(galleryConfig, "ThumbnailQuality").equals("high") ? 90 : 70;
    thumbnailCaption    = Boolean.valueOf(cms.contentshow(galleryConfig, "ThumbnailCaption")).booleanValue();
    downloadLinks       = Boolean.valueOf(cms.contentshow(galleryConfig, "DownloadLinks")).booleanValue();
    downloadFolderUri   = cms.contentshow(galleryConfig, "DownloadFolder");
}


int galleryIndex            = INDEX_FIRST_GALLERY;
try {
    // unboxing will trigger exception on null value
    galleryIndex = ((Integer)request.getAttribute("galleryIndex")).intValue();
} catch (Exception e) {}


String headingType = DEFAULT_HEADING_TYPE;
try {
    // unboxing will trigger exception on null value
    headingType = ((String)request.getAttribute("headingType")).toString();
} catch (Exception e) {}

// Check for thumbnail size overridde
try {
    // unboxing will trigger exception on null value
    thumbnailSize = ((Integer)request.getAttribute("thumbnailSize")).intValue();
} catch (Exception e) {}


String imagePath            = null;
String imageName            = null;
String imageTitle           = null;
String imageDescr           = null;
String imageByline          = null;

CmsResourceFilter imgFilter = CmsResourceFilter.DEFAULT.requireType(CmsResourceTypeImage.getStaticTypeId());
//List fullSizeImages = cms.getCmsObject().getFilesInFolder(galleryFolderUri, imgFilter);
List<CmsResource> images = cms.getCmsObject().readResources(galleryFolderUri, imgFilter, true);
Iterator iImages = images.iterator();

CmsImageScaler imageHandle = null; // use image scaler => easier to read width&height

String LABEL_TITLE          = CmsAgent.elementExists(title) ? title : cms.getCmsObject().readPropertyObject(galleryFolderUri, "Title", false).getValue("Gallery");
//final String LABEL_INFO           = cms.labelUnicode("info.gallery.viewnativesize");
//final String LABEL_STAT           = cms.labelUnicode("label.gallery.numberofimages") + ": " + images.size();

//HTML LAYOUT 
if (!IS_INCLUDED) {
    cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[0], true);
}

out.println("<" + headingType + ">" + LABEL_TITLE + "</" + headingType + ">");

//out.println("<h3>" + LABEL_INFO + "</h3>");
//out.println("<h4>" + LABEL_STAT + "</h4>");

if (CmsAgent.elementExists(text)) {
    if (IS_INCLUDED) {
        out.println(text);
    } else {
        out.println("<div class=\"ingress\">" + text + "</div>");
    }
}

if (iImages.hasNext()) {
    try {
        %>
        
        <div class="slides gallery" data-gallery-index="<%= galleryIndex %>" itemscope itemtype="http://schema.org/ImageGallery">
        <%
        for (CmsResource image : images) {
        //while (iImages.hasNext()) {
            //image       = (CmsResource)iImages.next();
            imageName   = image.getName();
            imagePath   = galleryFolderUri.concat(imageName);
            imageTitle  = cms.getCmsObject().readPropertyObject(image, "Title", false).getValue();
            imageDescr  = cms.getCmsObject().readPropertyObject(image, "Description", false).getValue("");
            imageByline = cms.getCmsObject().readPropertyObject(image, "byline", false).getValue("");
            
            imageHandle = new CmsImageScaler(cms.getCmsObject(), image);
            
            String largeDimStr = "" + imageHandle.getWidth() + "x" + imageHandle.getHeight();
            
            String imageTag = ImageUtil.getImage(cms, 
                    cmso.getSitePath(image), // original (large) image
                    cmso.readPropertyObject(image, CmsPropertyDefinition.PROPERTY_TITLE, false).getValue(""), // use the "Title" property as alt text
                    ImageUtil.CROP_RATIO_1_1, // square image
                    400, // maxAbsoluteWidth
                    50, //maxViewportRelativeWidth
                    ImageUtil.SIZE_M, 
                    thumbnailQuality, 
                    "800px");
            // Add some classes to the image (should really be possible with ImageUtil...)
            imageTag = "<img class=\"slide__image\" itemprop=\"thumbnail\" "
                        + imageTag.substring("<img ".length());
            
            // Show download links?
            if (downloadLinks) {
                String fileBaseName = StringUtils.substringBeforeLast(imageName, ".");
                String fileExtension = StringUtils.substringAfterLast(imageName, ".").toUpperCase();
                
                String dlStr = "<a class=\"galleryimage-dl cta alt download\" href=\"" + cmso.getSitePath(image) + "\" target=\"_blank\">" 
                                        + fileExtension + "</a>";
                
                if (CmsAgent.elementExists(downloadFolderUri)) {
                    List allDownloadFiles = cmso.readResources(downloadFolderUri, CmsResourceFilter.DEFAULT_FILES, true);
                    Iterator iAllDownloadFiles = allDownloadFiles.iterator();
                    while (iAllDownloadFiles.hasNext()) {
                        CmsResource downloadFile = (CmsResource)iAllDownloadFiles.next();
                        String downloadFileBaseName = StringUtils.substringBeforeLast(downloadFile.getName(), ".");
                        if (downloadFileBaseName.equalsIgnoreCase(fileBaseName)) {
                            String downloadFileExtension = StringUtils.substringAfterLast(downloadFile.getName(), ".").toUpperCase();
                            dlStr += " <span class=\"galleryimage-dl-separator\">|</span> "
                                    + "<a class=\"galleryimage-dl cta alt download\" href=\"" + cms.link(cmso.getSitePath(downloadFile)) + "\" target=\"_blank\">" 
                                            + downloadFileExtension + "</a>";
                        }
                    }
                }
                
                imageDescr +=  (imageDescr.isEmpty() ? "" : "<br />") + dlStr;
            }
            
            %>
            <figure class="slide gallerythumb" itemprop="associatedMedia" itemscope itemtype="http://schema.org/ImageObject">
                <a href="<%= cms.link(cmso.getSitePath(image)) %>" itemprop="contentUrl" data-dimensions="<%= largeDimStr %>">
                    <%= imageTag %>
                </a>
                <% if (!imageDescr.isEmpty() || !imageByline.isEmpty()) { %>
                <figcaption itemprop="caption description" class="caption caption--slide">
                    <p class="caption__text">
                        <%= CmsAgent.stripParagraph(imageDescr) %>
                        <% if (!imageByline.isEmpty()) { %>
                        <span class="credit"> <%= imageByline %></span>
                        <% } %>
                    </p>
                </figcaption>
                <% } %>
                <%= (thumbnailCaption ? ("<span class=\"gallerythumb__title\" style=\"\">" + imageTitle + "</span>") : "") %>
            </figure>
            <%
        } // END while (more images in gallery)
        %>
        </div>
        <%
    }
    catch (java.lang.OutOfMemoryError e) { 
        throw new ServletException("Out of memory while processing images."); 
    }
}
if (galleryIndex == INDEX_FIRST_GALLERY) {
    // NOTE: jQuery must be loaded first.
    //          This is the only jQuery dependency in PhotoSwipe.
    //          To elimitate the jQuery dependency, simply use 
    //          document.write(...) in the code snippet direcly below.
%>
<script type="text/javascript">
$(document).ready(function() {
    //console.log('appending pswp skeleton');
    // Root element of PhotoSwipe. Must have class pswp.
    $('body').append('<div class="pswp" id="pswp-root" tabindex="-1" role="dialog" aria-hidden="true">'
        // Background of PhotoSwipe. 
        // It's a separate element, as animating opacity is faster than rgba().
        + '<div class="pswp__bg"></div>'

        // Slides wrapper with overflow:hidden.
        + '<div class="pswp__scroll-wrap">'
            // Container that holds slides. 
            // PhotoSwipe keeps only 3 of them in the DOM to save memory.
            // Do not modify these 3 pswp__item elements, data is added later on.
            +' <div class="pswp__container">'
                + '<div class="pswp__item"></div>'
                + '<div class="pswp__item"></div>'
                + '<div class="pswp__item"></div>'
            + '</div>'

            // Default (PhotoSwipeUI_Default) interface on top of sliding area.
            // Can be changed.
            + '<div class="pswp__ui pswp__ui--hidden">'
                +' <div class="pswp__top-bar">'

                    // Controls are self-explanatory. Order can be changed.
                    + '<div class="pswp__counter"></div>'

                    + '<button class="pswp__button pswp__button--close" title="<%= cms.label("pswp.ui.text.close") %>"></button>'
                    +' <button class="pswp__button pswp__button--share" title="<%= cms.label("pswp.ui.text.share") %>"></button>'
                    + '<button class="pswp__button pswp__button--fs" title="<%= cms.label("pswp.ui.text.fullscreen") %>"></button>'
                    + '<button class="pswp__button pswp__button--zoom" title="<%= cms.label("pswp.ui.text.zoom") %>"></button>'

                    // Preloader demo http://codepen.io/dimsemenov/pen/yyBWoR
                    // Element will get class pswp__preloader--active when preloader is running.
                    + '<div class="pswp__preloader">'
                        + '<div class="pswp__preloader__icn">'
                          + '<div class="pswp__preloader__cut">'
                            + '<div class="pswp__preloader__donut"></div>'
                          + '</div>'
                        + '</div>'
                    + '</div>'
                + '</div>'

                + '<div class="pswp__share-modal pswp__share-modal--hidden pswp__single-tap">'
                    + '<div class="pswp__share-tooltip"></div>'
                + '</div>'

                + '<button class="pswp__button pswp__button--arrow--left" title="<%= cms.label("pswp.ui.text.previous") %>"></button>'
                + '<button class="pswp__button pswp__button--arrow--right" title="<%= cms.label("pswp.ui.text.next") %>"></button>'

                + '<div class="pswp__caption">'
                    + '<div class="pswp__caption__center"></div>'
                + '</div>'
            + '</div>'
        + '</div>'
    + '</div>'
    );
    // Initialize PhotoSwipe!
    initPhotoSwipeFromDOM('.slides');
});// doc.ready()
</script>
<%
}

//HTML LAYOUT 
if (!IS_INCLUDED)
    cms.include(cms.getTemplate(), cms.getTemplateIncludeElements()[1], true);
%>
