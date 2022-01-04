import { override } from '@microsoft/decorators';
import { Log } from '@microsoft/sp-core-library';
import {
  BaseApplicationCustomizer,
  PlaceholderContent,
  PlaceholderName
} from '@microsoft/sp-application-base';
import { Dialog } from '@microsoft/sp-dialog';
import styles from './CustomFooterApplicationCustomizer.module.scss';
import { escape } from '@microsoft/sp-lodash-subset';

import * as strings from 'CustomFooterApplicationCustomizerStrings';

const LOG_SOURCE: string = 'CustomFooterApplicationCustomizer';

export interface ICustomFooterApplicationCustomizerProperties {
  TopText: string;
  InlineFooterText: string;
  StickyFooterText: string;
  ShowHeader: boolean;
  ShowInlineFooter: boolean;
  ShowStickyFooter: boolean;
}

export default class CustomFooterApplicationCustomizer
  extends BaseApplicationCustomizer<ICustomFooterApplicationCustomizerProperties> {

  private _topPlaceholder: PlaceholderContent | undefined;
  private _bottomPlaceholder: PlaceholderContent | undefined;

  @override
  public onInit(): Promise<void> {
    Log.info(LOG_SOURCE, `Initialized ${strings.Title}`);

    this.context.placeholderProvider.changedEvent.add(this, this._renderPlaceHolders);

    return Promise.resolve();
  }

  private _renderPlaceHolders(): void {
    Log.info(LOG_SOURCE,"HelloWorldApplicationCustomizer._renderPlaceHolders()");
    Log.info(LOG_SOURCE,
      "Available placeholders: " +
      this.context.placeholderProvider.placeholderNames
        .map(name => PlaceholderName[name])
        .join(", ")
    );

    // Handling the top placeholder
    if (!this._topPlaceholder) {
      this._topPlaceholder = this.context.placeholderProvider.tryCreateContent(
        PlaceholderName.Top,
        { onDispose: this._onDispose }
      );

      // The extension should not assume that the expected placeholder is available.
      if (!this._topPlaceholder) {
        Log.error(LOG_SOURCE, new Error("The expected placeholder (Top) was not found."));
        return;
      }

      if (this.properties && this.properties.ShowHeader) {
        let topString: string = this.properties.TopText;
        if (!topString) {
          topString = "(Top property was not defined.)";
        }
  
        if (this._topPlaceholder.domElement) {
          this._topPlaceholder.domElement.innerHTML = `
          <div class="${styles.app}">
            <div class="${styles.top}">
              <i class="ms-Icon ms-Icon--Info" aria-hidden="true"></i> ${escape(
                topString
              )}
            </div>
          </div>`;
        }
      }
    }

    // Method for sticky footer
    // Handling the bottom placeholder
    if (!this._bottomPlaceholder) {
      this._bottomPlaceholder = this.context.placeholderProvider.tryCreateContent(
        PlaceholderName.Bottom,
        { onDispose: this._onDispose }
      );

      // The extension should not assume that the expected placeholder is available.
      if (!this._bottomPlaceholder) {
        Log.error(LOG_SOURCE, new Error("The expected placeholder (Bottom) was not found."));
        return;
      }

      if (this.properties && this.properties.ShowStickyFooter) {
        let stickeyString: string = this.properties.StickyFooterText;
        if (!stickeyString) {
          stickeyString = "(Bottom property was not defined.)";
        }
  
        if (this._bottomPlaceholder.domElement) {
          this._bottomPlaceholder.domElement.innerHTML = `
          <div class="${styles.app}">
            <div class="${styles.stickybottom}">
              <i class="ms-Icon ms-Icon--Info" aria-hidden="true"></i> ${escape(
                stickeyString
              )}
            </div>
          </div>`;
        }
      }
    }

    // Method for inline footer
    let inlineString: string = "";
    let sections = document.getElementsByClassName("Canvas");
    if (sections && sections[0] && this.properties.InlineFooterText) {
      if (this.properties) {
        inlineString = this.properties.InlineFooterText;
        if (!inlineString) {
          inlineString = "(Inline property was not defined.)";
        }
      }

      let mainContent = sections[0];
      Log.info(LOG_SOURCE, "mainContent element found.");

      if (mainContent.innerHTML) {
        mainContent.innerHTML += `
        <div class="${styles.app}">
          <div class="${styles.pinnedbottom}">
            <i class="ms-Icon ms-Icon--Info" aria-hidden="true"></i> ${escape(inlineString)}
          </div>
        </div>`;
      }

    }
  }

  private _onDispose(): void {
    Log.info(LOG_SOURCE, '[HelloWorldApplicationCustomizer._onDispose] Disposed custom top and bottom placeholders.');
  }
}
