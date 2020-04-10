import { Version } from '@microsoft/sp-core-library';
import {
  BaseClientSideWebPart,
  IPropertyPaneConfiguration,
  PropertyPaneTextField
} from '@microsoft/sp-webpart-base';
import { escape } from '@microsoft/sp-lodash-subset';

import styles from './HtmlWebPartWebPart.module.scss';
import * as strings from 'HtmlWebPartWebPartStrings';

export interface IHtmlWebPartWebPartProps {
  htmlContent: string;
}

export default class HtmlWebPartWebPart extends BaseClientSideWebPart<IHtmlWebPartWebPartProps> {

  public render(): void {
    if (this.properties.htmlContent != null && this.properties.htmlContent.length > 0) {
      this.domElement.innerHTML = `${this.properties.htmlContent}`;
    } else {
      this.domElement.innerHTML = `<div>Edit the web part properties to display HTML.</div>`;
    }
  }

  protected get dataVersion(): Version {
    return Version.parse('1.0');
  }

  protected getPropertyPaneConfiguration(): IPropertyPaneConfiguration {
    return {
      pages: [
        {
          header: {
            description: strings.PropertyPaneDescription
          },
          groups: [
            {
              groupName: strings.BasicGroupName,
              groupFields: [
                PropertyPaneTextField('htmlContent', {
                  label: 'HTML Content',
                  multiline: true,
                  resizable: true
                })
              ]
            }
          ]
        }
      ]
    };
  }
}
