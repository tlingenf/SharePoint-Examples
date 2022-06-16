import * as React from 'react';
import * as ReactDOM from 'react-dom';
import { Guid, Log } from '@microsoft/sp-core-library';
import {
  BaseFieldCustomizer,
  IFieldCustomizerCellEventParameters
} from '@microsoft/sp-listview-extensibility';
import * as strings from 'AttachmentPopoutFieldCustomizerStrings';
import AttachmentPopout, { IAttachmentPopoutProps } from './components/AttachmentPopout';

/**
 * If your field customizer uses the ClientSideComponentProperties JSON input,
 * it will be deserialized into the BaseExtension.properties object.
 * You can define an interface to describe it.
 */
export interface IAttachmentPopoutFieldCustomizerProperties {
}

const LOG_SOURCE: string = 'AttachmentPopoutFieldCustomizer';

export default class AttachmentPopoutFieldCustomizer
  extends BaseFieldCustomizer<IAttachmentPopoutFieldCustomizerProperties> {

  public onInit(): Promise<void> {
    // Add your custom initialization to this method.  The framework will wait
    // for the returned promise to resolve before firing any BaseFieldCustomizer events.
    Log.info(LOG_SOURCE, 'Activated AttachmentPopoutFieldCustomizer with properties:');
    Log.info(LOG_SOURCE, JSON.stringify(this.properties, undefined, 2));
    Log.info(LOG_SOURCE, `The following string should be equal: "AttachmentPopoutFieldCustomizer" and "${strings.Title}"`);
    return Promise.resolve();
  }

  public onRenderCell(event: IFieldCustomizerCellEventParameters): void {
    // Use this method to perform your custom cell rendering.
    if (Number(event.listItem.getValueByName("Attachments")) > 0) {
      const attachmentPopout: React.ReactElement<{}> = React.createElement(AttachmentPopout, {
        spHttpClient: this.context.spHttpClient,
        listId: this.context.pageContext.list.id,
        siteUrl: this.context.pageContext.web.absoluteUrl,
        itemId: event.listItem.getValueByName("ID"),
        title: event.listItem.getValueByName("Title")
      } as IAttachmentPopoutProps);
      ReactDOM.render(attachmentPopout, event.domElement);
    }
  }

  public onDisposeCell(event: IFieldCustomizerCellEventParameters): void {
    // This method should be used to free any resources that were allocated during rendering.
    // For example, if your onRenderCell() called ReactDOM.render(), then you should
    // call ReactDOM.unmountComponentAtNode() here.
    ReactDOM.unmountComponentAtNode(event.domElement);
    super.onDisposeCell(event);
  }
}
