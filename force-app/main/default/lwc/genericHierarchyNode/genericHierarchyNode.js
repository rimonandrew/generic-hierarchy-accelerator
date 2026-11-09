
import { LightningElement, api } from 'lwc';

export default class GenericHierarchyNode extends LightningElement {
    @api node;

    get hasChildren() {
        return this.node?.children?.length > 0;
    }

    get displayFields() {
        if (!this.node?.fieldValues) {
            return [];
        }

        return Object.entries(this.node.fieldValues).map(
            ([fieldName, value]) => ({
                fieldName,
                value: value === null || value === undefined
                    ? ''
                    : String(value)
            })
        );
    }

    get nodeClass() {
        return this.node?.isCurrent
            ? 'hierarchy-node current-node'
            : 'hierarchy-node';
    }
}
