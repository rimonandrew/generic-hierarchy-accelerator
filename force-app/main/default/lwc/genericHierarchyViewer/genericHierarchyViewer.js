
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getHierarchy from '@salesforce/apex/GenericHierarchyController.getHierarchy';

export default class GenericHierarchyViewer extends LightningElement {
    @api recordId;
    @api configurationName = '';

    pageRecordId;
    hierarchy;
    error;
    isLoading = true;

    get effectiveRecordId() {
        return this.recordId || this.pageRecordId;
    }

    @wire(CurrentPageReference)
    getPageReference(pageReference) {
        if (!this.recordId && pageReference) {
            const currentRecordId = pageReference.attributes?.recordId;

            if (currentRecordId) {
                this.pageRecordId = currentRecordId;
                this.error = undefined;
                this.isLoading = true;
            } else {
                this.isLoading = false;
                this.error =
                    'This component requires a record page with a valid record ID.';
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
            this.isLoading = false;
        } else if (error) {
            this.hierarchy = undefined;
            this.error = this.getErrorMessage(error);
            this.isLoading = false;
        }
    }

    get hasHierarchy() {
        return !!this.hierarchy?.root;
    }

    get hasError() {
        return !!this.error;
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
