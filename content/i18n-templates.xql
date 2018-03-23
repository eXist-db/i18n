module namespace intl="http://exist-db.org/xquery/i18n/templates";

(:~
 : i18n template functions. Integrates the i18n library module. Called from the templating framework.
 :)
import module namespace i18n="http://exist-db.org/xquery/i18n";
import module namespace templates="http://exist-db.org/xquery/templates";

declare variable $intl:DEFAULT_LANG := "en";
(:~
 : Template function: calls i18n:process on the child nodes of $node.
 : Template parameters:
 :      lang=de Language selection
 :      catalogues=relative path    Path to the i18n catalogue XML files inside database
 :)
declare function intl:translate($node as node(), $model as map(*), $lang as xs:string?, $catalogues as xs:string?) {
    let $catalogues :=
        if ($catalogues) then
            $catalogues
        else
            session:get-attribute("i18n.catalog")
    let $cpath :=
        (: if path to catalogues is relative, resolve it relative to the app root :)
        if (starts-with($catalogues, "/")) then
            $catalogues
        else
            util:collection-name($node) || "/" || $catalogues
    let $lang :=
        if ($lang) then (
            session:set-attribute("i18n.lang", $lang),
            $lang
        ) else
            let $sessionLang := session:get-attribute("i18n.lang")
            return
                if ($sessionLang) then
                    $sessionLang
                else
                    let $header := request:get-header("Accept-Language")
                    let $headerLang :=
                        if ($header != "") then
                            let $lang := tokenize($header, "\s*,\s*")
                            return
                                replace($lang[1], "^([^-;]+).*$", "$1")
                        else
                            $intl:DEFAULT_LANG
                    let $supportedLang := collection($cpath)/catalogue/@xml:lang/string()
                    let $lang :=
                        if ($headerLang = $supportedLang) then
                            $headerLang
                        else
                            $intl:DEFAULT_LANG
                    return (
                        session:set-attribute("i18n.lang", $lang),
                        $lang
                    )
    let $translated :=
        i18n:process($node/*, $lang, $cpath, ())
    return
        element { node-name($node) } {
            $node/@*,
            templates:process($translated, $model)
        }
};
