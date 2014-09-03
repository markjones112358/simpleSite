<?php

$type = reset(url_array());
$name = end(url_array());
$experience = $experienceList->get_experience($type, $name);
$description = $experience->get_description();
if ($description == False) $description_text = "This post does not have any textual content yet. This message was generated by SimpleSite, the freely available, automatic website generation software.";
else $description_text = retrieve_and_clean($description, 160);

$p = new BasePage($experience->title,
                  $description_text,
                  header_small(),
                  footer(),
                  True);

$p->style_reference( url_static() . '/fancybox/source/jquery.fancybox.css?v=2.1.5');
$p->script_reference('http://code.jquery.com/jquery-latest.min.js');
$p->script_reference( url_static() . '/fancybox/source/jquery.fancybox.pack.js?v=2.1.5');
$p->readyScript('$(document).ready(function() {
    $(".fancybox").fancybox({
        openEffect  : "none",
        closeEffect : "none",
    });
});');
$p->append($experience->render());
$p->prepend(hr());
if ($description_text != False && (strpos(strtolower($description), 'desc') !== False)) {
    $p->prepend(p($description_text, array('class'=>'fSmall c2 m0')));
}
$p->prepend(h1(ucfirst($experience->title),array('class'=>'c1 c mainFont')));