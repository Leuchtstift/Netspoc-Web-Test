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
    'PolicyWeb.view.panel.form.ServiceDetails',
    {
        extend      : 'Ext.form.Panel',
        alias       : 'widget.servicedetails',
        defaultType : 'textfield',
        defaults    : { anchor : '100%' },
        border      : false,
        style       : { "margin-left" : "3px" },
        items       : [
            { fieldLabel : 'Name',
              name       : 'name',
              readOnly   : true
            },
            { fieldLabel : 'Beschreibung',
              name       : 'desc',
              readOnly   : true
            },
            { xtype : 'hidden',
              name  : 'all_owners'
            },
            {
                xtype      : 'fieldcontainer',
                fieldLabel : 'Verantwortung',
                layout     : 'hbox',
                items      : [
                    { id      : 'btn_switch_service_responsibility',
                      xtype   : 'button',
                      hidden  : true,
                      flex    : 0,
                      iconCls : 'icon-group'
                    },
                    { xtype      : 'textfield',
                      flex       : 1,
                      name       : 'owner1',
                      readOnly   : true
                    }
                ]
            }
        ]
    }
);