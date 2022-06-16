import { Guid, Log } from '@microsoft/sp-core-library';
import { Icon, initializeIcons } from '@fluentui/react';
import * as React from 'react';
import { SPHttpClient, SPHttpClientResponse } from '@microsoft/sp-http';
import FileLinkCallout from './FileLinkCallout';

import styles from './AttachmentPopout.module.scss';


export interface IAttachmentPopoutProps {
  spHttpClient: SPHttpClient;
  siteUrl: string;
  listId: Guid;
  itemId: number;
  title: string;
}

export interface IAttachmentPopoutState {
  isCalloutVisible: boolean;
  attachments: any;
}

const LOG_SOURCE: string = 'AttachmentPopout';

export default class AttachmentPopout extends React.Component<IAttachmentPopoutProps, IAttachmentPopoutState> {

  constructor(props: IAttachmentPopoutProps) {
    super(props);
    this.state = {
      isCalloutVisible: false,
      attachments: null
    };
  }
  
  public componentDidMount(): void {
    Log.info(LOG_SOURCE, 'React Element: AttachmentPopout mounted');
    initializeIcons();
  }

  public componentWillUnmount(): void {
    Log.info(LOG_SOURCE, 'React Element: AttachmentPopout unmounted');
  }

  public render(): React.ReactElement<{}> {
    return (
      <div className={styles.AttachmentPopout}>
        <div onMouseOver={this.toggleCallout.bind(this, true)} onMouseOut={this.toggleCallout.bind(this, false)}>
          <Icon id={`attachIcon_${this.props.itemId}`} iconName='Attach'  />
          {this.state.isCalloutVisible && (
            <FileLinkCallout attachments={this.state.attachments} itemId={this.props.itemId} title={this.props.title} ></FileLinkCallout>
          )}
        </div>
      </div>
    );
  }

  private getAttachments(): Promise<any> {
    return this.props.spHttpClient.get(`${this.props.siteUrl}/_api/Web/Lists(guid'${this.props.listId}')/Items(${this.props.itemId})/AttachmentFiles?$select=FileName,ServerRelativeUrl`, SPHttpClient.configurations.v1)
    .then((response: SPHttpClientResponse) => {
      return response.json();
    });
  }

  private toggleCallout(visible: boolean) : void {
    if (visible) {
      this.getAttachments()
        .then((results: any) => {
          this.setState({
            isCalloutVisible: true,
            attachments: results
          });
        });
    } else {
      this.setState({
        isCalloutVisible: false,
        attachments: null
      });
    }
  }
}
