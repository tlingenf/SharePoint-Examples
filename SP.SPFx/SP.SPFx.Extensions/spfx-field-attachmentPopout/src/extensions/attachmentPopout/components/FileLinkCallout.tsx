import { Guid, Log } from '@microsoft/sp-core-library';
import { Text, Callout, Link } from '@fluentui/react';
import * as React from 'react';

import styles from './AttachmentPopout.module.scss';

export interface IFileLinkCalloutProps {
    itemId: number;
    attachments: any;
    title: string;
}

const LOG_SOURCE: string = 'FileLinkCallout';

export default class FileLinkCallout extends React.Component<IFileLinkCalloutProps, {}> {
  
  public componentDidMount(): void {
    Log.info(LOG_SOURCE, 'React Element: AttachmentPopout mounted');
  }

  public componentWillUnmount(): void {
    Log.info(LOG_SOURCE, 'React Element: AttachmentPopout unmounted');
  }

  public render(): React.ReactElement<{}> {
    return (
        <Callout target={`#attachIcon_${this.props.itemId}`} className={styles.FileLinkCallout}>
            <Text block variant='large'>{this.props.title} attachments:</Text>
            <ul className={styles.LinkList}>
            {
                this.props.attachments.value.map((item, index) => {
                return (<li><Link href={item.ServerRelativeUrl}><Text block nowrap={true}>{item.FileName}</Text></Link></li>);
                })
            }
            </ul>
        </Callout>
    );
  }
}
