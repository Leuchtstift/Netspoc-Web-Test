/*
(C) 2014 by Daniel Brunkhorst <daniel.brunkhorst@web.de>
            Heinz Knutzen     <heinz.knutzen@gmail.com>

https://github.com/hknutzen/Netspoc-Web

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

Ext.define(
    'PolicyWeb.view.window.Search',
    {   
        id : 'window_search',
        extend  : 'Ext.window.Window',
        alias   : 'widget.searchwindow',

        initComponent : function() {
            // Force defaults
            Ext.apply(
                this,
                {
                    title       : 'IP-Adresse oder Zeichenkette suchen',
                    width       : 350, 
                    height      : 475,
                    resizable   : false,
                    closeAction : 'hide',
                    items       : [
                        this.buildSearchForm()
                    ]
                }
            );
            this.callParent(arguments);
        },
        
        buildSearchForm : function () {
            var datatip = new Ext.ux.DataTip();
            var form = Ext.widget(
                {
                    xtype         : 'form',
                    plugins       : datatip,
                    buttonAlign   : 'center',
                    bodyPadding   : 5,
                    width         : '100%',
                    fieldDefaults : {
                        labelAlign : 'left',
                        msgTarget  : 'top'
                    },
                    items : [
                        this.buildTabPanel(),
                        this.buildOptionsFieldSet(),
                        this.buildGeneralOptionsFieldSet()
                    ],
                    buttons : [
                        {   
                            id    : 'btn_search_start',
                            text  : 'Suche starten'
                        }
                    ]
                }
            );
            return form;
	},
        
        buildTabPanel : function() {
            var tab_panel = {
                xtype     : 'tabpanel',
                plain     : true,
                activeTab : 0,
                height    : 220,
                defaults  : {
                    bodyPadding : 10
                },
                items : [
                    this.buildIPSearchTab(),
                    this.buildGeneralSearchTab()
                ]
            };
            return tab_panel;
        },

        buildGeneralSearchTab : function() {
            var textfield = {
                id        : 'txtf_search_string',
                xtype     : 'textfield',
                name      : 'search_string',
                blankText : 'Eine Suche ohne Suchbegriff macht keinen Sinn',
                emptyText : 'Suchbegriff eingeben'
            };

            var fieldset = {
                xtype       : 'fieldset',
                title       : 'Suchbegriff',
                defaults    : { anchor : '100%' },
                items       : [
                    textfield
                ]
            };
            return {
                title    : 'Allgemeine Suche',
                layout   : 'anchor',
                items : [
                    fieldset,
                    this.buildOptionsCheckboxGroup()
                ]
            };
        },

        buildOptionsCheckboxGroup : function() {
            return {
                xtype       : 'checkboxgroup',
                columns     : 1,
                flex        : 5,
                defaults    : {
                    checked : false
                },
                items       : [
                    {   
                        id         : 'cb_search_description',
                        boxLabel   : 'Suche auch in Dienstbeschreibungen',
                        checked    : true,
                        name       : 'search_in_desc'
                    }
                ]
            };
        },
        
        buildGeneralOptionsCheckboxGroup : function() {
            return {
                xtype       : 'checkboxgroup',
                columns     : 1,
                flex        : 5,
                defaults    : {
                    checked : false
                },
                items       : [
                    {   
                        id         : 'cb_search_case_sensitive',
                        boxLabel   : 'Groß-/Kleinschreibung beachten',
                        name       : 'search_case_sensitive'
                    },
                    {   
                        id         : 'cb_search_exact',
                        boxLabel   : 'Suchergebnisse nur mit ' +
                            'exakter Übereinstimmung',
                        name       : 'search_exact'
                    },
                    {   
                        id         : 'cb_search_keep_foreground',
                        boxLabel   : 'Such-Fenster im Vordergrund halten',
                        name       : 'keep_front'
                    }
                ]
            };
        },
        
        buildGeneralOptionsFieldSet : function() {
            return {
                xtype       : 'fieldset',
                title       : 'Allgemeine Optionen',
                defaults    : { anchor : '100%' },
                items       : [
                    this.buildGeneralOptionsCheckboxGroup()
                ]
            };
        },

        buildOptionsFieldSet : function() {
            var sf_srv_cbg = {
                xtype      : 'checkboxgroup',
                layout     : 'hbox',
                //columns    : 3,
                vertical   : true,
                //flex       : 1,
                defaults   : {
                    checked    : true,
                    width      : 100
                },
                items      : [
                    {
                        id         : 'cb_search_own',
                        boxLabel   : 'Eigene',
                        name       : 'search_own'
                    },
                    {
                        id         : 'cb_search_used',
                        boxLabel   : 'Genutzte',
                        name       : 'search_used'
                    },
                    {
                        id         : 'cb_search_usable',
                        boxLabel   : 'Nutzbare',
                        name       : 'search_visible',
                        checked    : false
                    }
                ]
            };

            var cb = {
                xtype      : 'checkboxgroup',
                layout     : 'hbox',
                defaults   : {
                    checked    : false
                },
                items      : [
                    {
                        boxLabel   : 'Nur befristete Dienste suchen',
                        name       : 'search_disable_at',
                        id         : 'checkbox_FOO', // maybe change to 'cb_search_limited' ?
                        width      : 200
                    }
                ]
            };          

            return {
                // Fieldset with checkboxgroup to select
                // in which services should be searched.
                xtype       : 'fieldset',
                title       : 'In welchen Diensten suchen?',
                defaults    : { anchor : '100%' },
                items       : [
                    sf_srv_cbg,
                    cb
                ]
            };
        },

        buildIPSearchTab : function() {
            return {
                title : 'Ende-zu-Ende-Suche',
                items : [
                    this.buildIPSearchPanel()
                ]
            };
        },

        buildIPSearchPanel : function() {
            var cbg = {
                xtype      : 'checkboxgroup',
                columns    : 1,
                vertical   : true,
                flex       : 1,
                items      : [
                    {   
                        id         : 'cb_search_supernet',
                        boxLabel   : 'Übergeordnete Netze einbeziehen',
                        name       : 'search_supernet'
                    },
                    {   
                        id         : 'cb_search_subnet',
                        boxLabel   : 'Enthaltene Netze einbeziehen',
                        name       : 'search_subnet',
                        checked    : true
                    },
                    {   
                        id         : 'cb_search_range',
                        boxLabel   : 'Port-Ranges einbeziehen',
                        name       : 'search_range'
                    }
                ]
            };
            var fieldset = {
                xtype       : 'fieldset',
                title       : 'Wonach soll gesucht werden?',
                defaults    : { anchor : '100%' },
                items       : [
                    {
                        xtype          : 'textfield',
                        id             : 'txtf_search_ip1',
                        name           : 'search_ip1',
                        labelWidth     : 60,
                        margin         : '0 10 0 0', // top,r,b,l
                        padding        : '4 0 0 0',  // top,r,b,l
                        emptyText      : 'IP oder Zeichenkette',
                        loader         : {
                            url : 'html/ip_search_tooltip'
                        },
                        fieldLabel     : 'IP 1'
                    },
                    {
                        xtype          : 'textfield',
                        id             : 'txtf_search_ip2',
                        name           : 'search_ip2',
                        labelWidth     : 60,
                        margin         : '0 10 0 0', // top,r,b,l
                        padding        : '4 0 0 0',  // top,r,b,l
                        emptyText      : 'IP oder Zeichenkette',
                        loader         : {
                            url : 'html/ip_search_tooltip'
                        },
                        fieldLabel     : 'IP 2'
                    },
                    {
                        xtype          : 'textfield',
                        id             : 'txtf_search_proto',
                        name           : 'search_proto',
                        labelWidth     : 60,
                        margin         : '0 10 0 0', // top,r,b,l
                        padding        : '4 0 10 0', // top,r,b,l
                        emptyText      : 'Protokoll oder Port',
                        loader         : {
                            url : 'html/ip_search_proto_tooltip'
                        },
                        fieldLabel     : 'Protokoll'
                    },
                    cbg
                ]
            };
            return fieldset;
        }
    }
);   
