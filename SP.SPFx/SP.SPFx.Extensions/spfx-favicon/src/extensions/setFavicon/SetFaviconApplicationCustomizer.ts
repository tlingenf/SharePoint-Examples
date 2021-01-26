import { override } from '@microsoft/decorators';
import { Log } from '@microsoft/sp-core-library';
import {
  BaseApplicationCustomizer
} from '@microsoft/sp-application-base';
import { SPHttpClient, SPHttpClientResponse } from '@microsoft/sp-http';

import * as strings from 'SetFaviconApplicationCustomizerStrings';

const LOG_SOURCE: string = 'SetFaviconApplicationCustomizer';

/**
 * If your command set uses the ClientSideComponentProperties JSON input,
 * it will be deserialized into the BaseExtension.properties object.
 * You can define an interface to describe it.
 */
export interface ISetFaviconApplicationCustomizerProperties {
  // This is an example; replace with your own property
  faviconpath: string;
}

/** A Custom Action which can be run during execution of a Client Side Application */
export default class SetFaviconApplicationCustomizer
  extends BaseApplicationCustomizer<ISetFaviconApplicationCustomizerProperties> {

  @override
  public onInit(): Promise<void> {
    Log.info(LOG_SOURCE, `Initialized ${strings.Title}`);
        
    let url: string =  `${this.context.pageContext.site.absoluteUrl}/siteassets/favicon.ico`;

    const links = document.getElementsByTagName('link');
    let head = document.getElementsByTagName('head')[0];
    for (let i = 0; i < links.length; i++) {
      if (links[i].getAttribute('rel') === 'shortcut icon') {
        head.removeChild(links[i]);
      }
    }

    let link = document.querySelector("link[rel*='icon']") as HTMLElement || document.createElement('link') as HTMLElement;
    link.setAttribute('type', 'image/x-icon');
    link.setAttribute('rel', 'shortcut icon');
    link.setAttribute('href', url);
    document.getElementsByTagName('head')[0].appendChild(link);

    return Promise.resolve();
  }
}
