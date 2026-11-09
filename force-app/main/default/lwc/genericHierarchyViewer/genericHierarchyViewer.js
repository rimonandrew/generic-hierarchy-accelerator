
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getHierarchy from '@salesforce/apex/GenericHierarchyController.getHierarchy';

export default class GenericHierarchyViewer extends LightningElement {
    @api recordId;
    @api configurationName = 'Account_Hierarchy';

    hierarchy;
    error;
    isLoading = true;

    @wire(CurrentPageReference)
    getPageReference(pageReference) {
        if (!this.recordId && pageReference) {
            this.recordId = pageReference.attributes?.recordId;
        }
    }

    @wire(getHierarchy, {
        recordId: '$recordId',
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

    getErrorMessage(error) {
        return error?.body?.message ||
            error?.message ||
            'Unable to load hierarchy.';
    }
}
