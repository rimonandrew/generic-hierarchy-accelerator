
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getHierarchy from '@salesforce/apex/GenericHierarchyController.getHierarchy';

export default class GenericHierarchyViewer extends LightningElement {
    @api recordId;
    @api configurationName = '';

    pageRecordId;
    hierarchy;
    error;
    _isLoading = true;

    get effectiveRecordId() {
        return this.recordId || this.pageRecordId;
    }

    // Only show the spinner when a record ID exists
    // and the hierarchy is still loading.
    get isLoading() {
        return Boolean(this.effectiveRecordId) && this._isLoading;
    }

    get hasError() {
        return Boolean(this.error) || !this.effectiveRecordId;
    }

    get errorMessage() {
        if (this.error) {
            return this.error;
        }

        if (!this.effectiveRecordId) {
            return 'This component requires a record page with a valid record ID.';
        }

        return '';
    }

    @wire(CurrentPageReference)
    getPageReference(pageReference) {
        if (!this.recordId && pageReference) {
            const currentRecordId = pageReference.attributes?.recordId;

            if (currentRecordId) {
                this.pageRecordId = currentRecordId;
                this.error = undefined;
                this._isLoading = true;
            }
        }
    }

    @wire(getHierarchy, {
        recordId: '$effectiveRecordId',
        configurationName: '$configurationName'
    })
    wiredHierarchy({ data, error }) {
        if (data) {
            this.hierarchy = data;
            this.error = undefined;
            this._isLoading = false;
        } else if (error) {
            this.hierarchy = undefined;
            this.error = this.getErrorMessage(error);
            this._isLoading = false;
        }
    }

    get hasHierarchy() {
        return Boolean(this.hierarchy?.root);
    }

    get isChildrenTruncated() {
        return this.hierarchy?.childrenTruncated === true;
    }

    getErrorMessage(error) {
        return error?.body?.message ||
            error?.message ||
            'Unable to load hierarchy.';
    }
}
