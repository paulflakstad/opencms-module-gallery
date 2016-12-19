<%
org.opencms.jsp.CmsJspActionElement cms = new org.opencms.jsp.CmsJspActionElement(pageContext, request, response);
String highslideGraphicsDir = cms.link("/system/modules/no.npolar.common.gallery/resources/highslide/graphics/");
%>
hs.graphicsDir = '<%= highslideGraphicsDir %>';
hs.align = 'center';
hs.marginBottom = 50;
hs.marginTop = 30;
hs.transitions = ['expand', 'crossfade'];
//hs.outlineType = 'glossy-dark';
//hs.wrapperClassName = 'dark';
hs.outlineType = 'rounded-white';
hs.fadeInOut = true;
hs.dimmingOpacity = 0.8;
hs.dimmingDuration = 300;

// Add the control bar
hs.addSlideshow({
    // slideshowGroup: 'group1',
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